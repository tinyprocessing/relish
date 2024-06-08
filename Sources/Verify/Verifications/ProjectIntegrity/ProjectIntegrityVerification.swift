
import Foundation

protocol ProjectIntegrityVerification {
    func verifyProject(
        _ projectContext: XcodeWorkspace.ProjectContext,
        using context: ProjectIntegrityWorkspaceContext
    ) throws -> ProjectIntegrityFailure.Issue?
}

struct ProjectIntegrityWorkspaceContext {
    var workspace: XcodeWorkspace
}
