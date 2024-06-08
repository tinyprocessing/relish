import Foundation

extension FormattedText {
    /// Concrete ``StyledText`` implementation representing italic text.
    struct ItalicText: StyledText {
        let value: String
    }
}

extension StyledText where Self == FormattedText.ItalicText {
    /// Convenience method to assist in the inlining of italic ``StyledText``.
    /// - Parameter value: The text value to apply italic styling to.
    ///
    /// - Returns: An instance of ``FormattedText.ItalicText``.
    static func italic(_ value: String) -> FormattedText.ItalicText {
        Self(value: value)
    }
}
