import Foundation

/// Protocol describing the requirements of a formatted text builder.
///
/// - NOTE: Utilizes the builder patter to assist in building out formatted text.
protocol FormattedTextBuilder {
    associatedtype TextStyler: TextStyling

    var textStyler: TextStyler { get }

    @discardableResult
    mutating func addHeader(_ header: FormattedText.Header) -> Self

    @discardableResult
    mutating func addBody(_ body: FormattedText.Body) -> Self

    @discardableResult
    mutating func addBlockQuote(_ blockQuote: FormattedText.BlockQuote) -> Self

    @discardableResult
    mutating func addCodeBlock(_ codeBlock: FormattedText.CodeBlock) -> Self

    @discardableResult
    mutating func addCollapsibleContent(_ collapsibleContent: FormattedText.CollapsibleContent) -> Self

    @discardableResult
    mutating func addList(_ list: FormattedText.List) -> Self

    @discardableResult
    mutating func addTable(_ table: FormattedText.Table) -> Self

    func formattedText() -> String
}

extension FormattedTextBuilder {
    func style(text: StyledText) -> String {
        switch text {
        case let text as FormattedText.BoldText:
            return textStyler.format(boldText: text)
        case let text as FormattedText.StrikethroughText:
            return textStyler.format(strikethroughText: text)
        case let text as FormattedText.ItalicText:
            return textStyler.format(italicText: text)
        case let text as FormattedText.ComplexText:
            return textStyler.format(complexText: text)
        case let text as String:
            return text
        default:
            preconditionFailure("An unsupported StyledText type was encountered. This is likely a developer error.")
        }
    }
}
