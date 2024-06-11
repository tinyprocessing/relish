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

    private let importRegex = try! NSRegularExpression(
        pattern: #"(?:\@testable\s+)?import\s+(?:(?:typealias|struct|class|enum|protocol|let|var|func)\s+)?([^\.\n]*)"#
    )

    private let canImportRegex = try! NSRegularExpression(
        pattern: #"#if canImport\(([a-zA-Z]+)\)"#
    )

    func verify(_ files: Set<URL>) throws {
        let swiftFiles = files.filter { $0.pathExtension == "swift" }
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

        let targetIssues: [ProjectIntegrityFailure.Issue] = try context.workspace.targetLookup.values
            .flatMap { targetContext -> [ProjectIntegrityFailure.Issue] in
                guard try targetContext.containsFiles(swiftFiles)
                    || changedProjectNames.contains(targetContext.projectContext.url.lastPathComponent)
                else {
                    return []
                }

                return try verifyTarget(targetContext)
            }

        guard targetIssues.isNotEmpty || projectIssues.isNotEmpty else {
            return
        }

        throw ProjectIntegrityFailure(issues: targetIssues + projectIssues)
    }

    func verifyAll() throws {
        let targetIssues = try targetIssues()
        let projectIssues = try projectIssues()
        guard targetIssues.isEmpty && projectIssues.isEmpty else {
            throw ProjectIntegrityFailure(issues: targetIssues + projectIssues)
        }
    }

    private func targetIssues() throws -> [ProjectIntegrityFailure.Issue] {
        let targetIssues: [ProjectIntegrityFailure.Issue] = try context.workspace.targetLookup.values
            .flatMap { targetContext in try verifyTarget(targetContext) }

        return targetIssues
    }

    private func projectIssues() throws -> [ProjectIntegrityFailure.Issue] {
        let projectIssues: [ProjectIntegrityFailure.Issue] = try context.workspace.projectLookup.values
            .flatMap { projectContext in try verifyProject(projectContext) }

        return projectIssues
    }

    func verifyProject(_ projectContext: XcodeWorkspace.ProjectContext) throws -> [ProjectIntegrityFailure.Issue] {
        let verifications: [ProjectIntegrityVerification] = [
            DeadReferenceProjectVerification(verbose: verbose),
            AbsolutePathsProjectVerification()
        ]

        return try verifications.compactMap { verification in
            try verification.verifyProject(projectContext, using: context)
        }
    }

    func verifyTarget(_ targetContext: XcodeWorkspace.TargetContext) throws -> [ProjectIntegrityFailure.Issue] {
        let imports: Set<SwiftImport> = try Set(targetContext.sourceFileURLs.flatMap { file -> [SwiftImport] in
            guard file.pathExtension == "swift",
                  let data = try? Data(contentsOf: file, options: .alwaysMapped)
            else {
                return []
            }

            let contents = String(decoding: data, as: UTF8.self)
            let canImports = Set(canImportRegex.formattedMatches(
                in: contents, range: contents.startIndex..<contents.endIndex
            )
            .map(\.captureGroups).flatMap { $0 })
            let imports = importRegex.formattedMatches(in: contents, range: contents.startIndex..<contents.endIndex)
                .map(\.captureGroups).flatMap { $0 }
                .filter { !canImports.contains($0) }

            return imports.map { SwiftImport(url: file, import: $0) }
        })

        let targetVerifications: [ProjectTargetIntegrityVerification] = [
            DuplicateTargetFilesVerification()
        ]

        let pluginTargets: [String: XcodeWorkspace.TargetContext] = Dictionary(
            uniqueKeysWithValues: context.workspace.targetLookup.values.filter { targetContext in
                targetContext.target.name == targetContext.projectContext.name
            }.map { ($0.target.name, $0) }
        )

        let integrityContext = ProjectIntegrityTargetContext(
            workspaceContext: context,
            imports: imports,
            pluginTargets: pluginTargets
        )

        return try targetVerifications.compactMap { verification in
            try verification.verifyTarget(targetContext, using: integrityContext)
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
