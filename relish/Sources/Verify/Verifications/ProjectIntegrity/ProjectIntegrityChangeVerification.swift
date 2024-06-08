import Foundation

struct ProjectIntegrityChangeVerification: ChangeVerification {
    enum VerificationType {
        case allFiles
        case changes(files: Set<URL>)
    }

    var verbose: Bool
    let name = "Project Integrity"
    let description = """
    Verifies that there are no integrity issues in Xcode project files.
    """

    func verify(context: ChangeContext) async throws {
        let changedFiles: Set<URL> = Set(context.files.compactMap { $0.isUpdated ? $0.url.absoluteURL : nil })
        try await perform(on: .changes(files: changedFiles))
    }

    func perform(on verificationType: VerificationType) async throws {
        let verifier = try await ProjectIntegrityVerifier.make(verbose: verbose)

        do {
            switch verificationType {
            case .allFiles:
                try verifier.verifyAll()
            case .changes(let files):
                try verifier.verify(files)
            }
        } catch let failure as ProjectIntegrityFailure {
            try throwFatal(.init(integrityIssues: failure.issues))
        }
    }
}

extension ProjectIntegrityChangeVerification {
    struct Failure: ChangeVerificationFailureProtocol {
        let integrityIssues: [ProjectIntegrityFailure.Issue]

        func issues() -> [ChangeVerificationFailure.Issue] {
            integrityIssues.map {
                .init(
                    description: .standardDescription(
                        $0.description,
                        recoverySuggestion: $0.recoverySuggestion
                    )
                )
            }
        }
    }
}
