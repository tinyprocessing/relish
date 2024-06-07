import Foundation

/// A failure that occurred during the `verify()` step of a ``ChangeVerification`` type.
struct ChangeVerificationFailure: Error {
    /// Type describing the severity of a ChangeVerificationFailure
    enum Severity {
        case fatal
        case warning
    }

    /// ``ChangeVerificationFailure/Issue``s that caused the verification to fail.
    var issues: [Issue]

    /// The ``Severity`` of the issues that caused the verification to fail.
    var severity: Severity

    /// The ``ChangeVerification`` that failed.
    var verification: any ChangeVerification

    /// An Issue that has cause the ``ChangeVerification`` to fail
    struct Issue {
        /// The description of the issue, conforms to ``ChangeVerificationIssueDescribing``.
        var description: ChangeVerificationIssueDescribing
    }
}

/// Describes the requirements of types used to describe a change verification issue.
protocol ChangeVerificationIssueDescribing {
    func asTextualElement() -> [any TextualElement]
}

extension ChangeVerificationFailure.Issue {
    /// Type providing a simple description of a ``ChangeVerificationFailure/Issue``.
    struct StandardDescription: ChangeVerificationIssueDescribing {
        var description: String
        var recoverySuggestion: String?

        func asTextualElement() -> [any TextualElement] {
            let elements: [TextualElement?] = [
                .body(description),
                recoverySuggestion.map { .blockQuote([$0]) }
            ]

            return elements.compactMap { $0 }
        }
    }

    /// Type providing a custom description of a ``ChangeVerificationFailure/Issue``.
    /// Requires the consumer to provide the entirety of the descriptions ``TextualElement``s.
    struct CustomDescription: ChangeVerificationIssueDescribing {
        let makeDescription: () -> [any TextualElement]

        func asTextualElement() -> [any TextualElement] {
            return makeDescription()
        }
    }
}

extension ChangeVerificationIssueDescribing where Self == ChangeVerificationFailure.Issue.StandardDescription {
    static func standardDescription(
        _ description: String,
        recoverySuggestion: String? = nil
    )
        -> ChangeVerificationFailure.Issue.StandardDescription {
        return .init(
            description: description,
            recoverySuggestion: recoverySuggestion
        )
    }
}

extension ChangeVerificationIssueDescribing where Self == ChangeVerificationFailure.Issue.CustomDescription {
    static func customDescription(
        _ builder: @escaping () -> [any TextualElement]
    )
        -> ChangeVerificationFailure.Issue.CustomDescription {
        return .init(makeDescription: builder)
    }
}
