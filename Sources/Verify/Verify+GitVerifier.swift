import ArgumentParser
import Foundation

extension Verify {
    /// Fetches the changed files from git and verifies they pass a set of `ChangeVerification`s.
    struct GitVerifier {
        var isVerbose: Bool
        var verifications: [any ChangeVerification]

        private var verificationNames: String { verifications.map(\.name).joined(separator: ", ") }

        func verify() async throws {
            let console = Console<NeverThrows>(isVerbose: isVerbose)

            let changeProvider = GitChangeProvider(isVerbose: isVerbose)
            let changeVerifier = ChangeVerifier(
                isVerbose: isVerbose,
                changeProvider: changeProvider,
                verifications: verifications
            )

            console.log(.step("Performing the following verifications: \(verificationNames)"))

            let result = try await changeVerifier.verify()
            try await processResult(result)
        }

        private func processResult(_ result: Result<Void, ChangeVerifier.Failure>) async throws {
            let console = Console<NeverThrows>(isVerbose: isVerbose)

            switch result {
            case .success:
                console.log(.success("\(verificationNames) verifications passed."))

            case .failure(let failure):
                console.log(.failure(
                    """
                    Your local changes did not pass verifications:
                        - Failures: \(failure.fatalFailures.map(\.verification.name))\n
                        - Warnings: \(failure.warnings.map(\.verification.name))\n
                    """
                ))
                console.log(.message(failure.gitComment))

                // If no failures are present (only warnings) do not fail the command.
                guard failure.fatalFailures.isNotEmpty else { return }

                throw ExitCode.failure
            }
        }
    }
}

extension ChangeVerifier.Failure {
    var gitComment: String {
        let failureComments = fatalFailures.map(\.consoleMessage)
        let warningComments = warnings.map(\.consoleMessage)

        var message = ""

        if failureComments.isNotEmpty {
            message.append(
                """
                Errors:
                \(failureComments.joined(separator: "\n\n"))
                """
            )
        }

        if warningComments.isNotEmpty {
            message.append("\n")
            message.append(
                """
                Warnings:
                \(warningComments.joined(separator: "\n\n"))
                """
            )
        }

        return message
    }
}

extension ChangeVerificationFailure {
    var consoleMessage: String {
        let elements = issues.flatMap { $0.description.asTextualElement() }

        return """
        🔴 \(verification.name): \(verification.description)
        \(TextFormatter.consoleMessageString(from: elements))
        """
    }
}
