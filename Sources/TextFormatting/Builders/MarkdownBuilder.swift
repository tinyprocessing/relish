import Foundation

/// Concrete implementation of ``FormattedTextBuilder`` used to build markdown formatted text.
struct MarkdownBuilder: FormattedTextBuilder {
    struct TextStyler: TextStyling {
        func format(boldText: FormattedText.BoldText) -> String {
            "**\(boldText.value)**"
        }

        func format(italicText: FormattedText.ItalicText) -> String {
            "*\(italicText.value)*"
        }

        func format(strikethroughText: FormattedText.StrikethroughText) -> String {
            "~~\(strikethroughText.value)~~"
        }
    }

    let textStyler = TextStyler()

    private let joinSeparator = "\n\n"
    private var components: [String] = []

    @discardableResult
    mutating func addHeader(_ header: FormattedText.Header) -> MarkdownBuilder {
        let token = String(repeating: "#", count: header.level.rawValue)
        components.append("\(token) \(style(text: header.text))")
        return self
    }

    @discardableResult
    mutating func addBody(_ body: FormattedText.Body) -> MarkdownBuilder {
        components.append(
            body
                .sections
                .map { style(text: $0) }
                .joined(separator: joinSeparator)
        )

        return self
    }

    @discardableResult
    mutating func addBlockQuote(_ blockQuote: FormattedText.BlockQuote) -> MarkdownBuilder {
        let quotedContent = blockQuote
            .sections
            .map { style(text: $0) }
            .joined(separator: joinSeparator)

        components.append(
            """
            <blockquote>
            \(quotedContent)
            </blockquote>
            """
        )

        return self
    }

    @discardableResult
    mutating func addCodeBlock(_ codeBlock: FormattedText.CodeBlock) -> MarkdownBuilder {
        components.append(
            """
            ```\(codeBlock.syntax.rawValue)
            \(codeBlock.codeBlock)
            ```
            """
        )

        return self
    }

    @discardableResult
    mutating func addCollapsibleContent(_ collapsibleContent: FormattedText.CollapsibleContent) -> MarkdownBuilder {
        // You must maintain an empty line after </summary> and </details> for the collapsible to work
        components.append(
            """
            <details>
            <summary>\(style(text: collapsibleContent.summaryText))</summary>

            \(TextFormatter.markdownString(from: collapsibleContent.elements))
            </details>

            """
        )

        return self
    }

    @discardableResult
    mutating func addList(_ list: FormattedText.List) -> MarkdownBuilder {
        let listContent = list
            .items
            .map { "* \(style(text: $0))" }
            .joined(separator: "\n")

        components.append(
            """
            \(style(text: list.heading)):
            \(listContent)
            """
        )

        return self
    }

    @discardableResult
    mutating func addTable(_ table: FormattedText.Table) -> MarkdownBuilder {
        let headingLine = "| \(table.headings.map { style(text: $0) }.joined(separator: " | ")) |"
        let separatorLine = """
        | \(table.headings.map {
            String(repeating: "-", count: ($0 as? String)?.count ?? 1)
        }.joined(separator: " | ")) |
        """

        var lines = [headingLine, separatorLine]

        for mapping in table.mappings {
            let valuesString = mapping.valueTexts.map { style(text: $0) }.joined(separator: " | ")
            lines.append("| \(style(text: mapping.nameText)) | \(valuesString) |")
        }

        components.append(
            """
            \(lines.joined(separator: "\n"))
            """
        )

        return self
    }

    func formattedText() -> String {
        components.joined(separator: joinSeparator)
    }
}
