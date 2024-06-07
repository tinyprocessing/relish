import Foundation

extension FormattedText {
    /// Concrete ``StyledText`` implementation representing bold text.
    struct BoldText: StyledText {
        let value: String
    }
}

extension StyledText where Self == FormattedText.BoldText {
    /// Convenience method to assist in the inlining of bold ``StyledText``.
    /// - Parameter value: The text value to apply bold styling to.
    ///
    /// - Returns: An instance of ``FormattedText.BoldText``.
    static func bold(_ value: String) -> FormattedText.BoldText {
        Self(value: value)
    }
}
