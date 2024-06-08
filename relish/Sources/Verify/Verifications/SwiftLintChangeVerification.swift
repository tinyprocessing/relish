import Foundation

/// Verifies the changed `.swift` files pass `swiftlint`.
struct SwiftLintChangeVerification: ChangeVerification {
    let name = "SwiftLint"

    let description = """
    Verifies that there are no SwiftLint violations in any of the modified swift files.
    """

    func verify(context: ChangeContext) async throws {
        let lintableFiles = context.swiftFiles.filter(\.isUpdated)

        guard lintableFiles.isNotEmpty else {
            return
        }

        for (index, file) in lintableFiles.enumerated() {
            setenv("SCRIPT_INPUT_FILE_\(index)", file.url.path, 1)
        }
        setenv("SCRIPT_INPUT_FILE_COUNT", String(lintableFiles.count), 1)

        let swiftlintCommand =
            """
            swiftlint lint \
            --config ~/relish/.violations.swiftlint.yml \
            --use-script-input-files --force-exclude --quiet --strict 2>&1
            """

        do {
            try await Shell(command: swiftlintCommand).process()
        } catch Shell.Error.failure(_, _, let output) {
            guard let output = output else { return }

            try throwFatal(.init(output: output))
        } catch {
            throw error
        }
    }
}

extension SwiftLintChangeVerification {
    struct Failure: ChangeVerificationFailureProtocol {
        struct Violation {
            var fileLocation: String
            var error: String

            var file: String {
                String(fileLocation.prefix(while: { $0 != ":" }))
            }

            init?(rawViolation: String) {
                guard let errorRange = rawViolation.range(of: "error:") else {
                    return nil
                }

                let fileString = rawViolation[..<errorRange.lowerBound]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .removing(prefix: FileManager.default.currentDirectoryPath)
                    .removing(prefix: "/")
                    .removing(suffix: ":")
                let errorString = rawViolation[errorRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)

                fileLocation = fileString
                error = errorString
            }
        }

        let violations: [Violation]

        init(output: String) {
            violations = output
                .components(separatedBy: "\n")
                .compactMap { Violation(rawViolation: $0) }
        }

        func issues() -> [ChangeVerificationFailure.Issue] {
            return [
                .init(
                    description: .customDescription {
                        [
                            .list(
                                withHeading: "SwiftLint failed with the following error(s)",
                                items: violations.map {
                                    """
                                    📁 File: \($0.fileLocation)
                                    ❌ Error: \($0.error)
                                    """
                                }
                            ),
                            .body(
                                "Resolve SwiftLint errors.",
                                "SwiftLint can resolve some errors automatically:"
                            ),
                            .codeBlock("""
                            swiftlint lint \
                            --config ~/relish/.violations.swiftlint.yml \
                            --quiet --fix
                            """)
                        ]
                    }
                )
            ]
        }
    }
}
