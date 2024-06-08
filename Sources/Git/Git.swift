import Foundation

class Git {
    enum Error: Swift.Error {
        case invalidCommandOutput(String)
        case invalidURL(String)
    }

    private(set) var currentBranch: String
    private(set) var previousBranch: String?

    // TODO: Wrap known get errors in a ThrowableError case for better logs.

    let console: Console<NeverThrows>

    init(isVerbose: Bool) async throws {
        console = .init(isVerbose: isVerbose)

        currentBranch = try await Shell(
            command: "git branch --show-current"
        ).process()
    }

    func createBranch(withName name: String) async throws {
        console.log(.step("Creating branch: \(name)"))

        previousBranch = currentBranch

        try await Shell(command: "git checkout -b \(name)", usePosix: true).process()

        currentBranch = name
    }

    func checkoutBranch(withName name: String) async throws {
        console.log(.step("Checking out to branch: \(name)"))

        previousBranch = currentBranch

        try await Shell(command: "git checkout \(name)", usePosix: true).process()

        currentBranch = name
    }

    func addFiles(matching: String) async throws {
        console.log(.step("Adding files matching: \(matching)"))

        try await Shell(command: "git add \(matching)").process()
    }

    func commit(withMessage message: String) async throws {
        console.log(.step("Committing changes with message: \(message)"))

        try await Shell(command: "git commit -m \"\(message)\"").process()
    }

    func push(toBranch branch: String) async throws {
        console.log(.step("Pushing changes to branch: \(branch)"))

        try await Shell(command: "git push origin \(branch)").process()
    }

    func pull(fromBranch branch: String, remote: String = "origin") async throws {
        console.log(.step("Pulling changes from branch \(remote):\(branch)"))

        try await Shell(command: "git pull \(remote) \(branch)").process()
    }

    func clone(source: String, tagOrBranch: String? = nil, depth: Int? = 1, destination: String? = nil) async throws {
        guard source.hasSuffix(".git") else {
            throw Error.invalidURL("Please use a base Git URL that ends in .git")
        }
        let tagOrBranchParameter = tagOrBranch.map { "--branch \($0)" } ?? ""
        let depthParameter = depth.map { "--depth \($0)" } ?? ""
        console.log(.step("Cloning: \(source) - \(tagOrBranch ?? "HEAD")"))
        try await Shell(command: "git clone \(depthParameter) \(tagOrBranchParameter) \(source) \(destination ?? "")")
            .process()
    }

    func delete(localBranch: String) async throws {
        console.log(.step("Deleting local branch with name: \(localBranch)"))

        try await Shell(command: "git branch -D \(localBranch)").process()
    }

    func delete(remoteBranch: String) async throws {
        console.log(.step("Deleting remote branch with name: \(remoteBranch)"))

        try await Shell(command: "git push origin --delete \(remoteBranch)").process()
    }

    func changedFiles() async throws -> [GitChange] {
        let fileList = try await Shell(command: "git status --porcelain=v1 -uall").process(shouldTrim: false)

        return fileList.split(separator: "\n").compactMap { GitChange(String($0)) }
    }

    func restore(changes: [GitChange]) async throws {
        for change in changes {
            guard change.isTracked else {
                try await Shell(command: "rm -rf \(change.fileURL.absoluteString)").process()
                return
            }

            if change.isStaged {
                try await Shell(command: "git restore --staged \(change.fileURL.absoluteString)").process()
            }

            try await Shell(command: "git restore \(change.fileURL.absoluteString)").process()
        }
    }

    func currentlyChangedProjects() async -> [String] {
        do {
            let output = try await Shell(command: "git status --porcelain").process()
            console.log(.info("Changed files:\n\(output)"))

            let paths: [String] = output.components(separatedBy: "\n")
                .compactMap { $0.split(separator: " ").last }
                .map { String($0) }
                .filter { $0.contains(".xcodeproj") }
                .compactMap {
                    guard $0.hasSuffix("project.pbxproj") else { return nil }
                    return $0.split(separator: "/").dropLast().joined(separator: "/")
                }
            return Array(Set(paths))

        } catch {
            console.log(.info("Failed to find any changed files"))
            return []
        }
    }

    func numberOfCommits(since commit: String) async throws -> Int {
        let command = "git rev-list --count \(commit)..HEAD"
        let output = try await Shell(command: command).process()

        guard let count = Int(output) else {
            throw Error.invalidCommandOutput(output)
        }

        return count
    }

    func lastCommitChanging(fileAtPath path: String) async throws -> String {
        let command = "git log --follow -1 --pretty=%H \(path)"
        let output = try await Shell(command: command).process()

        return output
    }

    func lastCommit(matchingMessagePattern pattern: String) async throws -> String {
        let command = #"git log  --grep="\#(pattern)" --pretty=format:"%h" -n 1"#
        let output = try await Shell(command: command).process()

        return output
    }

    /// Tries to determine the branch from which the current branch was based.
    /// Only looks for `origin/release/...` or `origin/development` branches, not feature or other branches.
    ///  - Parameter maxCommitDepth: The number of prior commits through which to look back. Defaults to 50.
    ///  - Returns: The branch found or throws a `GitError` if one was not found.
    func determineBaseBranch(_ maxCommitDepth: Int = 50) async throws -> String {
        // Command to list remote branches that contain the named commit.
        // In other words, the branches whose tip commits are descendants of the named commit.
        let pattern = #"(origin\/release\/.+)|(origin\/development)"#

        // Until we have merged, our HEAD~1, HEAD~2 etc commits will not yet be in any remote
        // development or release branch.
        // We use this fact to look for a remote branch containing one of the commits in our branch's
        // commit history. This indicates we found the ancestor branch.
        for i in 1...maxCommitDepth {
            if let remoteBranch = try await remoteBranchContainingCommit(at: i, matching: pattern) {
                console.log(.info("Remote base branch: \(remoteBranch)"))
                return remoteBranch
            }
        }
        console.log(.info("Remote base branch not found"))
        throw GitError(message: "Could not determine base branch")
    }

    /// Dump of remote branches that contain the commit from our history at the given index.
    ///  - Parameter index: The commit index where 1 is the last commit, 2 the 2nd last etc.
    ///  - Returns: The output from a `git branch -r --contains HEAD~\(index)` command.
    func remoteBranchesContaining(commitAt index: Int) async throws -> String {
        let commandPrefix = "git branch -r --contains HEAD~"
        let command = commandPrefix + "\(index)"
        let shell = Shell(command: command)
        return try await shell.process()
    }

    /// Looks for a remote branch that contains the commit from our history at the given index.
    ///  - Parameter index: The commit index where 1 is the last commit, 2 the 2nd last etc.
    ///  - Parameter pattern: A regex pattern to look for. Used to find the branch.
    ///  - Returns: The name of the remote branch or nil if not found.
    func remoteBranchContainingCommit(at index: Int, matching pattern: String) async throws -> String? {
        var remoteBranch: String?
        let response = try await remoteBranchesContaining(commitAt: index)
        if let range = response.range(of: pattern, options: .regularExpression) {
            remoteBranch = String(response[range])
        }
        return remoteBranch
    }

    func isRebaseCommit() async -> Bool {
        do {
            let output1 = try await Shell(
                command: "test -d \"$(git rev-parse --git-path rebase-merge)\""
            ).process()
            let output2 = try await Shell(
                command: "test -d \"$(git rev-parse --git-path rebase-apply)\""
            ).process()

            return !output1.isEmpty || !output2.isEmpty
        } catch {
            guard let shellError = error as? Shell.Error,
                  case .failure(_, let errorCode, let out) = shellError
            else {
                return false
            }

            return errorCode != 1 && !(out?.isEmpty ?? true)
        }
    }

    func isMergeCommit() async -> Bool {
        do {
            let output = try await Shell(command: "git rev-parse -q --verify MERGE_HEAD").process()

            return !output.isEmpty
        } catch {
            guard let shellError = error as? Shell.Error,
                  case .failure(_, let errorCode, let out) = shellError
            else {
                return false
            }

            return errorCode != 1 && !(out?.isEmpty ?? true)
        }
    }
}

/// An error while working with Git.
struct GitError: Error {
    let message: String
}

extension StringProtocol {
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
}
