import Foundation

extension Git {
    /// See: https://git-scm.com/docs/git-diff-index
    /// --cached
    ///      Do not consider the on-disk file at all.
    /// --diff-filter=AM
    ///      Select only files that are Added (A) or Modified (M)
    /// --no-renames
    ///      Turn off rename detection, even when the configuration file gives the default to do so.
    /// Diffed against HEAD
    private func runDiffIndex() async throws -> String {
        let command = "git diff-index --cached --diff-filter=AM --no-renames HEAD"

        return try await Shell(command: command).process()
    }

    func getIndexDiffs() async throws -> [Diff] {
        let output = try await runDiffIndex()
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard !lines.isEmpty else {
            console.log(.info("No files staged"))
            return []
        }
        console.log(.info("Index has \(lines.count) changed files..."))

        let diffs: [Diff] = try lines.compactMap { line in
            let diff = try parseDiff(diff: line)
            guard diff.srcMode != "120000" else {
                // Do not process symlinks
                return nil
            }
            return diff
        }

        return diffs
    }

    /// Parse output from `git diff-index`
    private func parseDiff(diff: String) throws -> Diff {
        // Format: src_mode dst_mode src_hash dst_hash status/score? src_path dst_path?
        let diffPattern = "^:(\\d+) (\\d+) ([a-f0-9]+) ([a-f0-9]+) ([A-Z])(\\d+)?\\t([^\\t]+)(?:\\t([^\\t]+))?$"
        let regex = try NSRegularExpression(pattern: diffPattern, options: [])
        let nsrange = NSRange(diff.startIndex..<diff.endIndex, in: diff)

        var aDiff = Diff()
        var error: Error?

        regex.enumerateMatches(
            in: diff,
            options: [],
            range: nsrange
        ) { match, _, stop in
            guard let match = match else { return }

            guard match.numberOfRanges >= 8 else {
                error = Git.Error.invalidCommandOutput("diff-index output does not match required pattern: " + diff)
                stop.pointee = true
                return
            }
            if let captureRange1 = Range(match.range(at: 1), in: diff) {
                let string = String(diff[captureRange1])
                aDiff.srcMode = string.unlessZeroed
            }
            if let captureRange2 = Range(match.range(at: 2), in: diff) {
                let string = String(diff[captureRange2])
                aDiff.dstMode = string.unlessZeroed
            }
            if let captureRange3 = Range(match.range(at: 3), in: diff) {
                let string = String(diff[captureRange3])
                aDiff.srcHash = string.unlessZeroed
            }
            if let captureRange4 = Range(match.range(at: 4), in: diff) {
                let string = String(diff[captureRange4])
                aDiff.dstHash = string.unlessZeroed
            }

            guard let captureRange5 = Range(match.range(at: 5), in: diff) else {
                error = Git.Error.invalidCommandOutput("diff-index output does not include status: " + diff)
                stop.pointee = true
                return
            }
            aDiff.status = String(diff[captureRange5])

            if let captureRange6 = Range(match.range(at: 6), in: diff) {
                aDiff.score = String(diff[captureRange6])
            }

            guard let captureRange7 = Range(match.range(at: 7), in: diff) else {
                error = Git.Error.invalidCommandOutput("diff-index output does not include srcPath: " + diff)
                stop.pointee = true
                return
            }
            aDiff.srcPath = String(diff[captureRange7])

            if let captureRange8 = Range(match.range(at: 8), in: diff) {
                let string = String(diff[captureRange8])
                aDiff.dstPath = string
            }
        }
        if let error = error {
            throw error
        }
        return aDiff
    }

    /// Provide content for repository objects, outputting to a Pipe.
    func catFile(objectHash: String, to pipe: Pipe) async throws {
        let catFileCommand = "git cat-file -p \(objectHash)"
        let catFileShell = Shell(command: catFileCommand)
        try await catFileShell.process(stdOutPipe: pipe)
    }

    /// Compute object ID and creates a blob from contents of a Pipe
    func hashObject(input pipe: Pipe) async throws -> String {
        let hashObjectCommand = "git hash-object -w --stdin"
        let hashObjectShell = Shell(command: hashObjectCommand)
        let newHash = try await hashObjectShell.process(stdInPipe: pipe)
        return newHash
    }

    /// Checks if the content of the new object is empty.
    func objectIsEmpty(_ objectHash: String) async throws -> Bool {
        let catFileCommand = "git cat-file -p \(objectHash)"
        let catFileShell = Shell(command: catFileCommand)
        let content = try await catFileShell.process()
        return content.isEmpty
    }

    /// Updates the index (staging) using the new object.
    func replaceFileInIndex(dstMode: String, srcPath: String, newObjectHash: String) async throws {
        let command = "git update-index --cacheinfo \(dstMode),\(newObjectHash),\(srcPath)"
        let shell = Shell(command: command)
        try await shell.process()
    }

    /// Creates a patch from the index and applies it to the working file.
    func patchWorkingFile(srcPath: String, origHash: String, newHash: String) async throws {
        let diffCommand = "git diff --color=never \(origHash) \(newHash)"
        let diffShell = Shell(command: diffCommand)
        let diff = try await diffShell.process()

        // Substitute object hashes in patch header with path to working tree file
        // We need to add a line feed at the end for some reason to avoid
        // "git error: corrupt patch at line xx"
        // Regarding + "\n\n": Kind of hacky, but this seems necessary in order to
        // terminate the patch file with an actual new line. Maybe just on zsh?
        let patch = diff.replacingOccurrences(of: origHash, with: srcPath)
            .replacingOccurrences(of: newHash, with: srcPath)
            + "\n\n"

        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let temporaryFilename = ProcessInfo().globallyUniqueString

        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)

        let data: Data = patch.data(using: .utf8)!
        try data.write(to: temporaryFileURL, options: .atomic)

        // Command to apply patch from a patch file.
        let patchFile = temporaryFileURL.absoluteString.removing(prefix: "file://")
        let patchCommand = "git apply \(patchFile)"
        console.log(.info("Applying patch file \(patchFile)"))
        let patchShell = Shell(command: patchCommand)

        // Apply the patch
        try await patchShell.process()
    }
}

/// Represents a single diff from an `diff-index` command.
struct Diff {
    var srcMode: String?
    var dstMode: String?
    var srcHash: String?
    var dstHash: String?
    var status: String
    var score: String?
    var srcPath: String
    var dstPath: String

    init(
        srcMode: String? = nil,
        dstMode: String? = nil,
        srcHash: String? = nil,
        dstHash: String? = nil,
        status: String = "",
        score: String? = nil,
        srcPath: String = "",
        dstPath: String = ""
    ) {
        self.srcMode = srcMode
        self.dstMode = dstMode
        self.srcHash = srcHash
        self.dstHash = dstHash
        self.status = status
        self.score = score
        self.srcPath = srcPath
        self.dstPath = dstPath
    }
}

extension String {
    var unlessZeroed: String? {
        range(of: "^0+$", options: .regularExpression) != nil ? nil : self
    }
}
