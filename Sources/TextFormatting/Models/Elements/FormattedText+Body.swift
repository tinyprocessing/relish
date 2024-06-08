import Foundation

extension FormattedText {
    /// Concrete ``TextualElement`` implementation representing a body text element.
    struct Body: TextualElement {
        let sections: [any StyledText]
    }
}

extension TextualElement where Self == FormattedText.Body {
    /// Convenience method to assist in the inlining of a body ``TextualElement``.
    ///
    /// - Parameter sections: An array of objects conforming to ``StyledText`` to quote.
    ///
    /// - Returns: An instance of ``FormattedText.Body``.
    static func body(_ sections: any StyledText...) -> FormattedText.Body {
        Self(sections: sections)
    }
}
