import Foundation
import PathKit
import XcodeProj

struct XcodeWorkspace {
    /// A mapping of target names to their target context.
    ///
    /// - Important: Only native targets are currently supported.
    var targetLookup: [String: TargetContext]

    /// A mapping of project name to project context.
    var projectLookup: [String: ProjectContext]

    struct ProjectContext {
        /// The absolute URL to the project file.
        var url: URL
        var project: XcodeProj

        var name: String {
            url.deletingPathExtension().lastPathComponent
        }

        /// The directory containing the project.
        var projectDirectory: URL {
            url.deletingLastPathComponent()
        }

        var sharedSchemes: [SchemeContext] {
            project.sharedData?.schemes.map {
                SchemeContext(
                    url: url.appendingPathComponent("xcshareddata/xcschemes/\($0.name).xcscheme"),
                    scheme: $0
                )
            } ?? []
        }
    }

    struct SchemeContext {
        var url: URL
        var scheme: XCScheme
    }

    struct TargetContext {
        var target: PBXNativeTarget
        var projectContext: ProjectContext

        func containsFiles(_ files: Set<URL>) throws -> Bool {
            try sourceFileURLs.contains(where: files.contains(_:))
        }

        var sourceFileURLs: [URL] {
            get throws {
                try target.sourceFiles().compactMap { sourceFile in
                    guard let path = try sourceFile.fullPath(
                        sourceRoot: projectContext.url.deletingLastPathComponent().path
                    )
                    else {
                        return nil
                    }

                    return URL(fileURLWithPath: path)
                }
            }
        }

        var isStaticFramework: Bool {
            get throws {
                try (target.baseXCConfig(
                    for: "Debug",
                    projectPathURL: projectContext.url
                )?.flattenedBuildSettings()["MACH_O_TYPE"] as? String) == "staticlib"
            }
        }
    }
}

extension PBXNativeTarget {
    func baseXCConfig(for buildSettingsName: String, projectPathURL: URL) throws -> XCConfig? {
        guard let buildConfig = buildConfigurationList?.configuration(name: buildSettingsName)?.baseConfiguration else {
            return nil
        }

        guard let xcconfigFilePath = try buildConfig
            .fullPath(sourceRoot: projectPathURL.deletingLastPathComponent().path)
        else {
            return nil
        }

        return try XCConfig(path: Path(xcconfigFilePath), projectPath: Path(projectPathURL.path))
    }
}

extension XcodeWorkspace {
    /// Creates and returns a workspace object with all of the Xcode projects in the repository.
    static func relish() async throws -> Self {
        let directory = Directory()
        let contents = try directory.directoryContents(atPath: directory.currentPath)
        let projectFiles: [URL] = contents
            .compactMap { URL(string: $0) }
            .filter { $0.pathExtension == "xcodeproj" }
        return try workspace(from: projectFiles)
    }

    /// Creates and returns a workspace with the Xcode projects from `projectURLs`.
    static func workspace(from projectURLs: [URL]) throws -> Self {
        let projectContexts: [XcodeWorkspace.ProjectContext] = try projectURLs.map {
            try XcodeWorkspace.ProjectContext(url: $0, project: XcodeProj(pathString: $0.path))
        }

        let projectLookup: [String: XcodeWorkspace.ProjectContext] = Dictionary(
            uniqueKeysWithValues: projectContexts.map { ($0.url.lastPathComponent, $0) }
        )

        let targetProjects: [(String, XcodeWorkspace.TargetContext)] = projectContexts.flatMap { project in
            project.project.pbxproj.nativeTargets.map {
                ($0.name, XcodeWorkspace.TargetContext(target: $0, projectContext: project))
            }
        }

        return XcodeWorkspace(
            targetLookup: Dictionary(uniqueKeysWithValues: targetProjects),
            projectLookup: projectLookup
        )
    }
}

extension PBXNativeTarget {
    var targetDependencyNames: [String] {
        dependencies.compactMap(\.resolvedName)
    }
}
