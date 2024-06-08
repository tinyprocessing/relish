import Foundation
import PathKit
import XcodeProj

struct ProjectIntegrityFailure: Error {
    var issues: [Issue]

    struct Issue: CustomStringConvertible {
        var description: String
        var recoverySuggestion: String
    }
}

/// An object that inspects the Xcode project file and associated targets to find potential issues.
struct ProjectIntegrityVerifier {
    var context: ProjectIntegrityWorkspaceContext

    var console: Console<NeverThrows> {
        Logger.console
    }

    var verbose: Bool
    func verify(_ files: Set<URL>) throws {
        let projectFiles = Array(files.filter { $0.pathExtension == "pbxproj" })
        let changedProjectNames = Set(projectFiles
            .compactMap { context.workspace.projectLookup[$0.deletingLastPathComponent().lastPathComponent] }
            .map(\.url.lastPathComponent))

        let projectIssues: [ProjectIntegrityFailure.Issue] = try context.workspace.projectLookup.values
            .filter { projectContext in
                changedProjectNames.contains(projectContext.url.lastPathComponent)
            }
            .flatMap { projectContext in
                try verifyProject(projectContext)
            }

        guard projectIssues.isNotEmpty else {
            return
        }

        throw ProjectIntegrityFailure(issues: projectIssues)
    }

    func verifyAll() throws {}

    private func projectIssues() throws -> [ProjectIntegrityFailure.Issue] {
        let projectIssues: [ProjectIntegrityFailure.Issue] = try context.workspace.projectLookup.values
            .flatMap { projectContext in try verifyProject(projectContext) }

        return projectIssues
    }

    func verifyProject(_ projectContext: XcodeWorkspace.ProjectContext) throws -> [ProjectIntegrityFailure.Issue] {
        let verifications: [ProjectIntegrityVerification] = [
            DeadReferenceProjectVerification(verbose: verbose)
        ]

        return try verifications.compactMap { verification in
            try verification.verifyProject(projectContext, using: context)
        }
    }
}

extension ProjectIntegrityVerifier {
    /// Creates and returns a verifier using the project files in the repository.
    static func make(verbose: Bool) async throws -> Self {
        async let workspace = XcodeWorkspace.relish()

        return try ProjectIntegrityVerifier(
            context: ProjectIntegrityWorkspaceContext(
                workspace: await workspace
            ), verbose: verbose
        )
    }
}

extension PBXTargetDependency {
    var resolvedName: String? {
        name ?? target?.name ?? product?.productName
    }
}
