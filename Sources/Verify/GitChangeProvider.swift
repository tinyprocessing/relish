import Foundation

struct GitChangeProvider: ChangeProviding {
    var isVerbose: Bool

    func changeContext() async throws -> ChangeContext {
        let git = try await Git(isVerbose: isVerbose)
        let gitChangedFiles = try await git.changedFiles()
        let rootDirectory = try Directory().repoRootURL

        let changeFiles = gitChangedFiles.compactMap { ChangeFile(rootDirectory: rootDirectory, change: $0) }

        return .commit(files: changeFiles)
    }
}

extension ChangeFile {
    init?(rootDirectory: URL, change: GitChange) {
        guard let unstagedStatus = Status(change.theirDescriptor), let status = Status(change.ourDescriptor) else {
            return nil
        }

        let fileURL = URL(fileURLWithPath: change.fileURL.path, relativeTo: rootDirectory)

        self.init(url: fileURL, status: status, unstagedStatus: unstagedStatus)
    }
}

extension ChangeFile.Status {
    fileprivate init?(_ descriptor: GitChange.Descriptor) {
        switch descriptor {
        case .unmodified:
            self = .unchanged
        case .modified:
            self = .modified
        case .added:
            self = .added
        case .deleted:
            self = .deleted
        case .renamed:
            self = .renamed
        case .copied:
            self = .copied
        case .updatedButUnmerged:
            self = .updatedButUnmerged
        case .untracked, .ignored:
            return nil
        }
    }
}
