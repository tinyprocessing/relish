import Foundation

protocol ProjectTargetIntegrityVerification {
    func verifyTarget(
        _ targetContext: XcodeWorkspace.TargetContext,
        using context: ProjectIntegrityTargetContext
    ) throws -> ProjectIntegrityFailure.Issue?
}

struct SwiftImport: Hashable {
    var url: URL
    var `import`: String
}

struct ProjectIntegrityTargetContext {
    var workspaceContext: ProjectIntegrityWorkspaceContext
    var imports: Set<SwiftImport>
    var pluginTargets: [String: XcodeWorkspace.TargetContext]
}
