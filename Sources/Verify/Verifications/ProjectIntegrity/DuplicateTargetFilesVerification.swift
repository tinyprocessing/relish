import Foundation

struct DuplicateTargetFilesVerification: ProjectTargetIntegrityVerification {
    func verifyTarget(
        _ targetContext: XcodeWorkspace.TargetContext,
        using context: ProjectIntegrityTargetContext
    ) throws -> ProjectIntegrityFailure.Issue? {
        let duplicates = try targetContext.target.sourceFiles()
            .compactMap(\.path)
            .map { URL(fileURLWithPath: $0).lastPathComponent }
            .duplicates

        guard duplicates.isNotEmpty else {
            return nil
        }

        return ProjectIntegrityFailure.Issue(
            description: """
            "\(targetContext.target.name) in \(targetContext.projectContext.name) has source files with the same name:
            \(duplicates)
            """,
            recoverySuggestion: "Rename one of the source files or remove the duplicate(s)."
        )
    }
}
