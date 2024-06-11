import ArgumentParser
import Foundation

extension Verify {
    struct Project: RelishCommand {
        static let configuration: CommandConfiguration = .init(
            abstract: "Verify xcode project files."
        )

        static let commandName = "relish verify project"

        @OptionGroup()
        var options: Relish.Options

        func runCommand() async throws {
            let console = Console<NeverThrows>(isVerbose: options.verbose)
            let verifier = ProjectIntegrityChangeVerification(verbose: options.verbose)

            do {
                try await verifier.perform(on: .allFiles)
            } catch let error as ChangeVerificationFailure {
                console.log(.failure(error.consoleMessage))

                throw ExitCode.failure
            }
        }
    }

    struct ProjectSettings: RelishCommand {
        static let configuration: CommandConfiguration = .init(
            abstract: "Verify xcode project files."
        )

        static let commandName = "relish verify project-settings"

        @OptionGroup()
        var options: Relish.Options

        @Argument
        var path: String

        func runCommand() async throws {
            let console = Console<NeverThrows>(isVerbose: options.verbose)
            let verifier = ProjectIntegrityChangeVerification(verbose: options.verbose)

            do {
                let directory = Directory()
                let repoRoot = try directory.repoRootURL
                let file = ChangeFile(url: repoRoot.appendingPathComponent(path),
                                      status: .modified,
                                      unstagedStatus: .modified)
                try await verifier.perform(on: .changes(files: Set([file.url])))
            } catch let error as ChangeVerificationFailure {
                console.log(.failure(error.consoleMessage))

                throw ExitCode.failure
            }
        }
    }
}
