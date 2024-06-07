import Foundation

struct Shell {
    enum RunCommandError: Swift.Error {
        case WaitPIDError
        case POSIXSpawnError(Int32)
    }

    enum Error: Swift.Error, CustomStringConvertible, LocalizedError {
        case failure(Shell, Int32, String?)

        var description: String {
            switch self {
            case .failure(let shell, let code, let errorOutput):
                if shell.command.contains("cleanup") {
                    if let output = errorOutput {
                        return "\n\t" + output
                    }
                }
                var description = "Command \"\(shell.command)\" failed with code \(code)"
                if let output = errorOutput {
                    description += " and error:\n\t \(output)"
                }

                return description
            }
        }

        var errorDescription: String? {
            description
        }
    }

    private var shellOverride: String? {
        return ProcessInfo.processInfo.environment["RELISHCLI_SHELL"]
    }

    private let command: String
    private let usePosix: Bool

    /// Creates a wrapper around a shell command.
    ///
    /// - Parameters:
    ///   - command: The shell command to execute.
    ///   - usePosix: Whether to use posix conventions.
    init(command: String, usePosix: Bool = false) {
        self.command = command
        self.usePosix = usePosix
    }

    /// Runs a shell script and BLOCKs the current thread.
    ///
    /// - FIXME: Refactor to completion handler and async/await API.
    ///
    /// - Important Use ``asyncProcess()`` in the context of async/await to avoid thread pool exhaustion.
    @discardableResult private func nonAsyncProcess(
        using directory: Directory? = nil,
        shouldTrim: Bool = true,
        stdInPipe: Pipe? = nil,
        stdOutPipe: Pipe? = nil,
        stdErrPipe: Pipe? = nil,
        logOutput: Bool = false
    ) throws -> String {
        let console = Console<NeverThrows>(isVerbose: logOutput)

        if logOutput {
            console.verbose("Executing shell command: \(command)")
        }

        if usePosix {
            var pid: pid_t = 0
            let args = ["sh", "-c", command]
            let envs = ProcessInfo().environment.map { "\($0)=\($1)" }

            try withCStrings(args) { cArgs in
                try withCStrings(envs) { cEnvs in
                    var status = posix_spawn(&pid, "/bin/sh", nil, nil, cArgs, cEnvs)
                    if status == 0 {
                        if !(waitpid(pid, &status, 0) != -1) {
                            throw RunCommandError.WaitPIDError
                        }
                    } else {
                        throw RunCommandError.POSIXSpawnError(status)
                    }
                }
            }

            return ""
        }

        let task = Process()

        let stdOut = stdOutPipe ?? Pipe()
        let stdErr = stdErrPipe ?? Pipe()
        if let stdInPipe = stdInPipe {
            task.standardInput = stdInPipe
        }

        task.currentDirectoryPath = directory?.currentPath ?? FileManager.default.currentDirectoryPath
        task.standardOutput = stdOut
        task.standardError = stdErr
        task.arguments = ["--login", "-c", command]
        task.launchPath = shellOverride ?? "/bin/bash"

        // If client provided an output pipe we don't want to consume the contents of the task
        // to return as the String output of this function.
        // We leave it for the client to process.
        // i.e. they likely want the command's output in their pipe because
        // they are chaining it as input to another Shell command.
        guard stdOutPipe == nil else {
            task.launch()
            return ""
        }

        // modified advice of the great eskimo: https://developer.apple.com/forums/thread/690310
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "com.tinyprocessing.Shell.RelishCLI")

        group.enter()
        task.terminationHandler = { _ in
            queue.async {
                group.leave()
            }
        }

        // must be accessed on queue until after `group.wait()`
        var ioError: Swift.Error?

        // read from stdout
        group.enter()
        let stdOutFileDescriptor = stdOut.fileHandleForReading.fileDescriptor
        let stdOutReadIO = DispatchIO(type: .stream, fileDescriptor: stdOutFileDescriptor, queue: queue) { _ in
            try! stdOut.fileHandleForReading.close()
        }

        var stdOutput = Data()
        stdOutReadIO.read(offset: 0, length: .max, queue: queue) { isDone, dataChunk, error in
            dispatchPrecondition(condition: .onQueue(queue))

            stdOutput.append(contentsOf: dataChunk ?? .empty)

            guard isDone || error != EXIT_SUCCESS else {
                return
            }

            stdOutReadIO.close()

            if ioError == nil && error != EXIT_SUCCESS {
                ioError = NSError.posixError(error)
            }

            group.leave()
        }

        // read from stderr
        group.enter()
        let stdErrFileDescriptor = stdErr.fileHandleForReading.fileDescriptor
        let stdErrReadIO = DispatchIO(type: .stream, fileDescriptor: stdErrFileDescriptor, queue: queue) { _ in
            try! stdErr.fileHandleForReading.close()
        }

        var stdErrorOutput = Data()
        stdErrReadIO.read(offset: 0, length: .max, queue: queue) { isDone, dataChunk, error in
            dispatchPrecondition(condition: .onQueue(queue))

            stdErrorOutput.append(contentsOf: dataChunk ?? .empty)

            guard isDone || error != EXIT_SUCCESS else {
                return
            }

            stdErrReadIO.close()

            if ioError == nil && error != EXIT_SUCCESS {
                ioError = NSError.posixError(error)
            }

            group.leave()
        }

        task.launch()

        // wait for command to finish
        group.wait()

        let stdOutString = String(data: stdOutput, encoding: .utf8) ?? ""
        let stdErrString = String(data: stdErrorOutput, encoding: .utf8) ?? ""

        Console<NeverThrows>(isVerbose: logOutput).verbose(stdOutString)
        Console<NeverThrows>(isVerbose: logOutput).verbose(stdErrString)

        guard task.terminationStatus == 0 || ioError != nil else {
            throw Error.failure(
                self,
                task.terminationStatus,
                stdErrString.trimmed.isEmpty ? stdOutString : stdErrString
            )
        }

        let finalOutput = stdOutString.trimmed.isNotEmpty ? stdOutString : stdErrString

        return shouldTrim ? finalOutput.trimmingCharacters(in: .whitespacesAndNewlines) : finalOutput
    }

    private func withCStrings(_ strings: [String], scoped: ([UnsafeMutablePointer<CChar>?]) throws -> Void) rethrows {
        let cStrings = strings.map { strdup($0) }
        try scoped(cStrings + [nil])
        cStrings.compactMap { $0 }.forEach { free($0) }
    }
}

extension Shell {
    /// Executes the process asynchronously.
    ///
    /// - Parameter logOutput: A Boolean value that determines whether the output of the command is printed to the
    /// console.
    /// - Returns: The output of the process.
    @discardableResult func process(
        using directory: Directory? = nil,
        shouldTrim: Bool = true,
        stdInPipe: Pipe? = nil,
        stdOutPipe: Pipe? = nil,
        stdErrPipe: Pipe? = nil,
        logOutput: Bool = false
    ) async throws -> String {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Swift.Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(with: Result {
                    try self.nonAsyncProcess(
                        using: directory,
                        shouldTrim: shouldTrim,
                        stdInPipe: stdInPipe,
                        stdOutPipe: stdOutPipe,
                        stdErrPipe: stdErrPipe,
                        logOutput: logOutput
                    )
                })
            }
        }
    }
}

extension NSError {
    static func posixError(_ error: Int32) -> Error {
        NSError(domain: NSPOSIXErrorDomain, code: Int(error), userInfo: nil)
    }
}
