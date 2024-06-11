import Foundation

struct AbsolutePathsProjectVerification: ProjectIntegrityVerification {
    func verifyProject(
        _ projectContext: XcodeWorkspace.ProjectContext,
        using context: ProjectIntegrityWorkspaceContext
    ) throws -> ProjectIntegrityFailure.Issue? {
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
        projectContext.project.pbxproj.fileReferences.compactMap { fileReferencePath in
            guard let path = fileReferencePath.path, isPathAbsolute(path) else {
                return nil
            }

            return path
        }
    }

    private func isPathAbsolute(_ path: String) -> Bool {
        path.lowercased().contains("/users")
    }
}
