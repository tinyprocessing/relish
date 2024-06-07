import Foundation

/// Type that provides easy access to formatting text using a builder pattern.
///
/// Can be easily expanded to any formatted text representation by implementing a new object conforming to the
/// ``FormattedTextBuilder`` protocol.
///
/// Example Usage:
///  ```swift
///  let elements: [TextualElement] = [
///     .header(.one, .bold("Some Title")),
///     .body("some description or message that can be presented to a user.")
///  ]
///
///  let message = TextFormatter.markdownString(from: elements)
///  ```
///
struct TextFormatter {
    var builder: any FormattedTextBuilder

    /// Constructs the message by mutating the builder.
    ///
    /// - NOTE: PreconditionFailure will occur if an unsupported ``TextualElement`` type is used.
    /// This most likely represents a developer error.
    ///
    /// - Parameter elements: An array of objects conforming to ``TextualElement`` protocol, used to build the message.
    mutating func construct(with elements: [TextualElement]) {
        for element in elements {
            switch element {
            case let element as FormattedText.Header:
                builder.addHeader(element)
            case let element as FormattedText.Body:
                builder.addBody(element)
            case let element as FormattedText.BlockQuote:
                builder.addBlockQuote(element)
            case let element as FormattedText.CodeBlock:
                builder.addCodeBlock(element)
            case let element as FormattedText.CollapsibleContent:
                builder.addCollapsibleContent(element)
            case let element as FormattedText.List:
                builder.addList(element)
            case let element as FormattedText.Table:
                builder.addTable(element)
            default:
                preconditionFailure(
                    "An unsupported TextualElement type was encountered. This is likely a developer error."
                )
            }
        }
    }

    /// Creates the formatted text using the concrete ``FormattedTextBuilder`` object.
    ///
    /// - Returns: The desired formatted String.
    func string() -> String {
        builder.formattedText()
    }
}

extension TextFormatter {
    static func markdownString(from elements: [TextualElement]) -> String {
        return string(from: elements, using: MarkdownBuilder())
    }

    static func consoleMessageString(
        from elements: [TextualElement],
        formatter: ASCIIFormatter = GlobalASCIIFormatter()
    ) -> String {
        return string(from: elements, using: ConsoleMessageBuilder(formatter: formatter))
    }

    private static func string(
        from elements: [TextualElement],
        using builder: any FormattedTextBuilder
    )
        -> String {
        var constructor = TextFormatter(builder: builder)
        constructor.construct(with: elements)
        return constructor.string()
    }
}
