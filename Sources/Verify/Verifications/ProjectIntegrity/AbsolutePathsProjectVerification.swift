import Foundation

struct AbsolutePathsProjectVerification: ProjectIntegrityVerification {
    var verbose: Bool

    var console: Console<NeverThrows> {
        Logger.console
    }

    func verifyProject(
        _ projectContext: XcodeWorkspace.ProjectContext,
        using context: ProjectIntegrityWorkspaceContext
    ) throws -> ProjectIntegrityFailure.Issue? {
        if verbose {
            console.log(.step("AbsolutePathsProjectVerification"))
        }
        let absolutePaths = try absolutePaths(in: projectContext)

        guard absolutePaths.isNotEmpty else {
            return nil
        }

        return ProjectIntegrityFailure.Issue(
            description: """
            \(projectContext.name) contains files that use absolute paths instead of relative paths:
              - \(absolutePaths.joined(separator: "\n  - "))
            """,
            recoverySuggestion: """
            Use a relative path instead of an absolute path for the file.
            """
        )
    }

    private func absolutePaths(in projectContext: XcodeWorkspace.ProjectContext) throws -> [String] {
        return projectContext.project.pbxproj.fileReferences.compactMap { fileReferencePath in
            guard let path = fileReferencePath.path, isPathAbsolute(path) else {
                if verbose {
                    console.log(.message("\(fileReferencePath.path ?? "") is relative"))
                }
                return nil
            }
            if verbose {
                console.log(.warn("\(fileReferencePath.path ?? "") is absolute"))
            }
            return path
        }
    }

    private func isPathAbsolute(_ path: String) -> Bool {
        path.lowercased().contains("/users")
    }
}
