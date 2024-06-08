import Foundation

extension FormattedText {
    /// Concrete ``TextualElement`` implementation representing a code block text element.
    struct CodeBlock: TextualElement {
        enum Syntax: String {
            case swift
            case json
            case text
            case shell = "sh"
        }

        let syntax: Syntax
        let codeBlock: String
    }
}

extension TextualElement where Self == FormattedText.CodeBlock {
    /// Convenience method to assist in the inlining of a code block ``TextualElement``.
    /// - Parameters:
    ///   - codeBlock: String consisting of code to format as a code block.
    ///   - syntax: The ``FormattedText.CodeBlock.Syntax`` to use when highlighting.
    ///   Note, not all text format styles will support syntax highlighting.
    ///
    /// - Returns: An instance of ``FormattedText.CodeBlock``.
    static func codeBlock(
        _ codeBlock: String,
        usingSyntax syntax: FormattedText.CodeBlock.Syntax = .text
    ) -> FormattedText.CodeBlock {
        Self(syntax: syntax, codeBlock: codeBlock)
    }
}
