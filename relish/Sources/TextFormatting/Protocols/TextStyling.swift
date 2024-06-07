import Foundation

/// Protocol representing the requirements of formatting ``StyledText``.
protocol TextStyling {
    func format(boldText: FormattedText.BoldText) -> String
    func format(italicText: FormattedText.ItalicText) -> String
    func format(strikethroughText: FormattedText.StrikethroughText) -> String
}

extension TextStyling {
    func format(complexText: FormattedText.ComplexText) -> String {
        let formattedSegments = complexText.segments.map { segment in
            switch segment {
            case let segment as FormattedText.BoldText:
                return format(boldText: segment)
            case let segment as FormattedText.ItalicText:
                return format(italicText: segment)
            case let segment as FormattedText.StrikethroughText:
                return format(strikethroughText: segment)
            case let segment as FormattedText.ComplexText:
                return format(complexText: segment)
            case let segment as String:
                return segment
            default:
                preconditionFailure("An unsupported StyledText type was encountered. This is likely a developer error.")
            }
        }

        return formattedSegments.joined(separator: " ")
    }
}
