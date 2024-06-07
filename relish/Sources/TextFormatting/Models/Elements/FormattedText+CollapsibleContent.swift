import Foundation

extension FormattedText {
    /// Concrete ``TextualElement`` implementation representing a collapsible content text element.
    ///
    /// - Important: Not all formatted text types will support the collapsing of content like Markdown does, even
    /// some Markdown implementations will not.
    struct CollapsibleContent: TextualElement {
        let summaryText: any StyledText
        let elements: [any TextualElement]
    }
}

extension TextualElement where Self == FormattedText.CollapsibleContent {
    /// Convenience method to assist in the inlining of a collapsible content ``TextualElement``.
    /// - Parameters:
    ///   - elements: An array of objects conforming to ``TextualElement`` to next under the collapsing element.
    ///   - summaryText: A summary to use on the collapsing element interaction medium.
    ///
    /// - Returns: An instance of ``FormattedText.CollapsibleContent``.
    static func collapsingContent(
        _ elements: [any TextualElement],
        under summaryText: any StyledText
    ) -> FormattedText.CollapsibleContent {
        Self(summaryText: summaryText, elements: elements)
    }
}
