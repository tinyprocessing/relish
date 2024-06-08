import Foundation

extension FormattedText {
    /// Concrete ``TextualElement`` implementation representing a list text element.
    struct List: TextualElement {
        let heading: any StyledText
        let items: [any StyledText]
    }
}

extension TextualElement where Self == FormattedText.List {
    /// Convenience method to assist in the inlining of a list ``TextualElement``.
    ///
    /// - Parameters:
    ///   - heading: The heading ``StyledText`` to display above the list.
    ///   - items: Array of ``StyledText`` objects that the list will consist of.
    ///
    /// - Returns: An instance of ``FormattedText.List``.
    static func list(withHeading heading: any StyledText, items: [any StyledText]) -> FormattedText.List {
        Self(heading: heading, items: items)
    }
}
