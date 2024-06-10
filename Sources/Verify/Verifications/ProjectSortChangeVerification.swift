import Foundation

struct ProjectSortChangeVerification: ChangeVerification {
    let name = "Xcode Project Sort"

    let description = """
    Verifies that any modified Xcode project files are sorted. This helps prevent \
    merge conflicts and keeps files in a consistent order.
    """

    /// A Boolean value that determines if the project files are modified in-place.
    var modifyInPlace: Bool
    var verbose: Bool

    private static let script = "~/relish/xcodeproj_verifications/_cleanup_projects.py"

    func verify(context: ChangeContext) async throws {
        let unsortedProjects: [ChangeFile] = try await context.files.asyncFilter { file in
            guard file.isProjectFile && file.isUpdated else { return false }

            return try await !isValid(file)
        }

        guard unsortedProjects.isNotEmpty else {
            return
        }

        try throwFatal(
            .init(
                files: unsortedProjects,
                wasModifiedInPlace: modifyInPlace,
                repoRootURL: Directory().repoRootURL,
                scriptCommand: Self.script
            )
        )
    }

    private func isValid(_ file: ChangeFile) async throws -> Bool {
        let console = Console<Never>(isVerbose: verbose)

        do {
            let command = "python3 \(ProjectSortChangeVerification.script) -t --files \(file.url.path)"
            let shell = Shell(command: command)
            try await shell.process()

            return true

        } catch Shell.Error.failure(_, _, let output) {
            console.failure("\(name): \(output ?? "")")
            return false

        } catch {
            throw error
        }
    }

    /// Returns the original project file URLs or the URLs to the project files in a temporary directory if
    /// `modifyProjectFiles` is `false.
    private func makeProjectURL(from projectChangeFile: ChangeFile) throws -> URL {
        guard !modifyInPlace else {
            return projectChangeFile.url
        }

        let temporaryDirectory = try FileManager.default.createTemporaryDirectory()

        let projectDirectory = temporaryDirectory.appending(
            path: projectChangeFile.url.deletingLastPathComponent().lastPathComponent,
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: projectDirectory)

        let projectPath = projectChangeFile.url.pathComponents.suffix(2).joined(separator: "/")
        let newFileURL = temporaryDirectory.appendingPathComponent(projectPath)

        try FileManager.default.copyItem(at: projectChangeFile.url, to: newFileURL)

        return newFileURL
    }
}

extension ProjectSortChangeVerification {
    struct Failure: ChangeVerificationFailureProtocol {
        let files: [ChangeFile]
        let wasModifiedInPlace: Bool
        let repoRootURL: URL
        let scriptCommand: String

        func issues() -> [ChangeVerificationFailure.Issue] {
            if wasModifiedInPlace {
                let projects = files.map {
                    $0.url.path().replacingOccurrences(of: "\(repoRootURL.path)/", with: "")
                }
                return [
                    .init(
                        description: .customDescription {
                            [
                                .list(
                                    withHeading: "Xcode project sorting modified the following project(s)",
                                    items: projects
                                ),
                                .body(""),
                                .body(
                                    "Recovery suggestion: Include the modified project files with your changes."
                                )
                            ]
                        }
                    )
                ]

            } else {
                let projectPaths = files
                    .map { $0.url.relativePath.replacingOccurrences(of: "\(repoRootURL.path)/", with: "") }
                let fixCommand = "\(scriptCommand) --files \(projectPaths.joined(separator: " "))"

                return [
                    ChangeVerificationFailure.Issue(
                        description: .customDescription {
                            [
                                .body("Your change include unsorted Xcode project files."),
                                .body(
                                    """
                                    Include the modified project files after executing the following command \
                                    to sort the changed project files:
                                    """
                                ),
                                .codeBlock(fixCommand)
                            ]
                        }
                    )
                ]
            }
        }
    }
}

// MARK: - ChangeFile

extension ChangeFile {
    fileprivate var isProjectFile: Bool {
        url.pathExtension == "pbxproj"
    }
}
