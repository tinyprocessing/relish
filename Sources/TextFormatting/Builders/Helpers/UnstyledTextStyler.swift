import Foundation

/// Convenience implementation of the ``TextStyling`` protocol that can be used on ``FormattedTextBuilder``
/// implementations that do not support the styling of ``StyledText`` objects.
struct UnstyledTextStyler: TextStyling {
    func format(boldText: FormattedText.BoldText) -> String {
        boldText.value
    }

    func format(italicText: FormattedText.ItalicText) -> String {
        italicText.value
    }

    func format(strikethroughText: FormattedText.StrikethroughText) -> String {
        strikethroughText.value
    }
}
