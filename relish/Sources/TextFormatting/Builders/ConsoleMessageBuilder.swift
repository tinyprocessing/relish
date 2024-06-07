import Foundation

/// Concrete implementation of ``FormattedTextBuilder`` used to build console message formatted text.
struct ConsoleMessageBuilder: FormattedTextBuilder {
    let textStyler = UnstyledTextStyler()

    var formatter: ASCIIFormatter

    private let joinSeparator = "\n"
    private var components: [String] = []

    init(formatter: ASCIIFormatter) {
        self.formatter = formatter
    }

    mutating func addHeader(_ header: FormattedText.Header) -> ConsoleMessageBuilder {
        let baseHeader = style(text: header.text)
        let styledHeader: String

        switch header.level {
        case .one:
            styledHeader = baseHeader.applyingAsciiFormatting(.cyanBold, formatter: formatter)
        case .two:
            styledHeader = baseHeader.applyingAsciiFormatting(.greenBold, formatter: formatter)
        case .three:
            styledHeader = baseHeader.applyingAsciiFormatting(.bold, formatter: formatter)
        case .four, .five, .six:
            styledHeader = baseHeader
        }

        components.append(styledHeader)
        return self
    }

    mutating func addBody(_ body: FormattedText.Body) -> ConsoleMessageBuilder {
        components.append(
            body
                .sections
                .map { style(text: $0) }
                .joined(separator: joinSeparator)
        )
        return self
    }

    mutating func addBlockQuote(_ blockQuote: FormattedText.BlockQuote) -> ConsoleMessageBuilder {
        let indent = "    "
        let quotedContent = blockQuote
            .sections
            .map { "\(indent)\(style(text: $0))" }
            .joined(separator: joinSeparator)

        components.append(
            """
            \(quotedContent)
            """
        )

        return self
    }

    mutating func addCodeBlock(_ codeBlock: FormattedText.CodeBlock) -> ConsoleMessageBuilder {
        components.append(
            """
            \(codeBlock.codeBlock)
            """
        )
        return self
    }

    mutating func addCollapsibleContent(_ collapsibleContent: FormattedText
        .CollapsibleContent) -> ConsoleMessageBuilder {
        // ASCII does not support inline HTML, instead we have chosen to just show the expanded content
        components.append(
            """
            \(TextFormatter.consoleMessageString(from: collapsibleContent.elements, formatter: formatter))
            """
        )
        return self
    }

    mutating func addList(_ list: FormattedText.List) -> ConsoleMessageBuilder {
        let listContent = list
            .items
            .map { "* \(style(text: $0))" }
            .joined(separator: joinSeparator)

        components.append(
            """
            \(style(text: list.heading)):
            \(listContent)
            """
        )

        return self
    }

    mutating func addTable(_ table: FormattedText.Table) -> ConsoleMessageBuilder {
        // NOT SUPPORTED
        return self
    }

    func formattedText() -> String {
        components.joined(separator: joinSeparator)
    }
}
