import Foundation
import XcodeProj

struct DeadReferenceProjectVerification: ProjectIntegrityVerification {
    private static let fileIgnoreList: Set<String> = []
    private static let extensionIgnoreList: Set<String> = ["xcframework"]
    private static let carthageFolder = "Carthage"

    func verifyProject(
        _ projectContext: XcodeWorkspace.ProjectContext,
        using context: ProjectIntegrityWorkspaceContext
    ) throws -> ProjectIntegrityFailure.Issue? {
        let deadReferences = projectContext.project.pbxproj.fileReferences
            .compactMap { $0.absoluteURL(from: projectContext.projectDirectory) }
            .filter { url in
                guard !Self.extensionIgnoreList.contains(url.pathExtension),
                      !Self.fileIgnoreList.contains(url.lastPathComponent),
                      !url.pathComponents.contains(Self.carthageFolder)
                else {
                    return false
                }

                return !FileManager.default.fileExists(atPath: url.path)
            }

        guard deadReferences.isNotEmpty else {
            return nil
        }

        let relativePaths = deadReferences.map { $0.absoluteString }

        return ProjectIntegrityFailure.Issue(
            description: """
            \(projectContext.name) contains broken ('dead') file references:
              - \(relativePaths.joined(separator: "\n  - "))
            """,
            recoverySuggestion: """
            Repair or remove the broken file reference from the project.
            """
        )
    }
}

extension PBXFileReference {
    fileprivate func absoluteURL(from projectDirectory: URL) -> URL? {
        guard let path, let sourceTree else { return nil }

        switch sourceTree {
        case .group:
            let pathComponents: [String] = sequence(first: parent, next: { $0?.parent })
                .compactMap { file -> String? in
                    guard let path = file?.path else {
                        return nil
                    }

                    switch file?.sourceTree {
                    case .sourceRoot:
                        /// we take the last path component while also preserving relative paths (../)
                        let components = path.components(separatedBy: "/")
                        let relativePath = components.filter { $0 == ".." }
                        let full = relativePath + [components.last!]

                        return full.joined(separator: "/")

                    default:
                        return path
                    }
                }

            let relativePath = (pathComponents.reversed() + [path]).joined(separator: "/")
            let url = projectDirectory.appendingPathComponent(relativePath)

            return url

        case .sourceRoot:
            return projectDirectory.appendingPathComponent(path)

        case .absolute, .buildProductsDir, .custom, .developerDir, .none, .sdkRoot:
            return nil
        }
    }
}
