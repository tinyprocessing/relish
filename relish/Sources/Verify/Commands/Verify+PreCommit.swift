import ArgumentParser
import Foundation

extension Verify {
    struct PreCommit: RelishCommand {
        static let configuration = CommandConfiguration(
            abstract: "Verify changes before committing (pre-commit hook)."
        )

        static let commandName = "relish verify pre-commit"

        @OptionGroup()
        var options: Relish.Options

        @Flag(
            name: .shortAndLong,
            help: "Run the project integrity scripts."
        )
        var project = false

        func runCommand() async throws {
            let git = try await Git(isVerbose: false)
            guard await !git.isMergeCommit(), await !git.isRebaseCommit() else {
                let console = Console<NeverThrows>(isVerbose: options.verbose)
                console.log(.step("Skipping pre-commit verification as this is either a merge or rebase commit...."))
                return
            }
            let verifier = try GitVerifier(
                isVerbose: options.verbose,
                verifications: Self.verifications(isVerbose: options.verbose)
            )
            try await verifier.verify()
        }
    }
}

extension Verify.PreCommit {
    @ListBuilder<ChangeVerification>
    static func verifications(
        includeProjectIntegrity: Bool = false,
        lint: Bool = true,
        modifyProjectFileInPlace: Bool = true,
        isVerbose: Bool
    ) throws -> [any ChangeVerification] {
        ProjectIntegrityChangeVerification()
    }
}
