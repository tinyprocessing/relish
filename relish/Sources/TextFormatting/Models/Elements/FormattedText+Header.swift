import Foundation

extension FormattedText {
    /// Concrete ``TextualElement`` implementation representing a header text element.
    struct Header: TextualElement {
        enum Level: Int {
            case one = 1
            case two
            case three
            case four
            case five
            case six
        }

        let level: Level
        let text: any StyledText
    }
}

extension TextualElement where Self == FormattedText.Header {
    /// Convenience method to assist in the inlining of a header ``TextualElement``.
    /// - Parameters:
    ///   - level: The ``FormattedText.Header.Level`` of the header.
    ///   - text: The title ``StyledText`` to display on the header.
    ///
    /// - Returns: An instance of ``FormattedText.Header``.
    static func header(_ level: FormattedText.Header.Level, _ text: any StyledText) -> FormattedText.Header {
        Self(level: level, text: text)
    }
}
