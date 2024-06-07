import Foundation

extension FormattedText {
    /// Concrete ``StyledText`` implementation representing strikethrough text.
    struct StrikethroughText: StyledText {
        let value: String
    }
}

extension StyledText where Self == FormattedText.StrikethroughText {
    /// Convenience method to assist in the inlining of strikethrough ``StyledText``.
    /// - Parameter value: The text value to apply strikethrough styling to.
    ///
    /// - Returns: An instance of ``FormattedText.StrikethroughText``.
    static func strikethrough(_ value: String) -> FormattedText.StrikethroughText {
        Self(value: value)
    }
}
