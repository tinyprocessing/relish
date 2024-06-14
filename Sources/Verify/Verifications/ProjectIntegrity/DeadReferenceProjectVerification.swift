import Foundation
import XcodeProj

struct DeadReferenceProjectVerification: ProjectIntegrityVerification {
    private static let fileIgnoreList: Set<String> = []
    private static let extensionIgnoreList: Set<String> = ["xcframework"]
    private static let carthageFolder = "Carthage"

    var verbose: Bool

    var console: Console<NeverThrows> {
        Logger.console
    }

    func verifyProject(
        _ projectContext: XcodeWorkspace.ProjectContext,
        using context: ProjectIntegrityWorkspaceContext
    ) throws -> ProjectIntegrityFailure.Issue? {
        if verbose {
            console.log(.step("DeadReferenceProjectVerification"))
        }
        let deadReferences = projectContext.project.pbxproj.fileReferences
            .compactMap { $0.absoluteURL(from: projectContext.projectDirectory) }
            .filter { url in
                guard !Self.extensionIgnoreList.contains(url.pathExtension),
                      !Self.fileIgnoreList.contains(url.lastPathComponent),
                      !url.pathComponents.contains(Self.carthageFolder)
                else {
                    return false
                }
                if verbose {
                    console.log(.message("\(url.path) fileExists: \(FileManager.default.fileExists(atPath: url.path))"))
                }
                return !FileManager.default.fileExists(atPath: url.path)
            }

        guard deadReferences.isNotEmpty else {
            return nil
        }

        let relativePaths = deadReferences.map { $0.absoluteString }

        let allReferences = projectContext.project.pbxproj.fileReferences
            .compactMap {
                $0.absoluteURL(from: projectContext.projectDirectory)?.relativeString
            }.joined(separator: "\n")

        printIfVerbose(verbose, """
        All file references:
        \(allReferences)
        """)

        return ProjectIntegrityFailure.Issue(
            description: """
            Project Error: \(projectContext.url.relativeString)
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
