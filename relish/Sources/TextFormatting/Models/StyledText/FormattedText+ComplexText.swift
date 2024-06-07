import Foundation

extension FormattedText {
    /// Concrete ``StyledText`` implementation representing complex text.
    ///
    /// - NOTE: This is used to facilitate the creation of strings with multiple overlayed styling.
    struct ComplexText: StyledText {
        let segments: [any StyledText]
    }
}

extension StyledText where Self == FormattedText.ComplexText {
    /// Convenience method to assist in the inlining of complex ``StyledText``.
    /// - Parameter value: The text value to apply complex styling to.
    ///
    /// - Returns: An instance of ``FormattedText.ComplexText``.
    static func complex(_ textSegments: (any StyledText)...) -> FormattedText.ComplexText {
        Self(segments: textSegments)
    }
}
