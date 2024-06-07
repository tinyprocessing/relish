import Foundation

extension FormattedText {
    /// Concrete ``TextualElement`` implementation representing a block quote text element.
    struct BlockQuote: TextualElement {
        let sections: [any StyledText]
    }
}

extension TextualElement where Self == FormattedText.BlockQuote {
    /// Convenience method to assist in the inlining of a block quote ``TextualElement``.
    ///
    /// - Parameter sections: An array of objects conforming to ``StyledText`` to quote.
    ///
    /// - Returns: An instance of ``FormattedText.BlockQuote``.
    static func blockQuote(_ sections: [any StyledText]) -> FormattedText.BlockQuote {
        Self(sections: sections)
    }
}

extension FormattedText {
    struct Table: TextualElement {
        struct Mapping {
            let nameText: any StyledText
            let valueTexts: [any StyledText]
        }

        let headings: [any StyledText]
        let mappings: [Mapping]

        init<Item>(items: [Item],
                   nameDetails: (keyPath: KeyPath<Item, String>, label: any StyledText),
                   valuesDetails: [(keyPath: KeyPath<Item, String>, label: any StyledText)],
                   nameStyleTransform: (String) -> any StyledText = { $0 },
                   valueStyleTransform: (String) -> any StyledText = { $0 }) {
            var headingsValues = [nameDetails.label]
            headingsValues.append(contentsOf: valuesDetails.map(\.label))

            headings = headingsValues
            mappings = items.map { item in
                Mapping(
                    nameText: nameStyleTransform(item[keyPath: nameDetails.keyPath]),
                    valueTexts: valuesDetails.map { detail in
                        valueStyleTransform(item[keyPath: detail.keyPath])
                    }
                )
            }
        }
    }
}

extension TextualElement where Self == FormattedText.Table {
    static func table<Item>(
        _ items: [Item],
        nameDetails: (keyPath: KeyPath<Item, String>, label: any StyledText),
        valuesDetails: [(keyPath: KeyPath<Item, String>, label: any StyledText)],
        nameStyleTransform: (String) -> any StyledText = { $0 },
        valueStyleTransform: (String) -> any StyledText = { $0 }
    )
        -> FormattedText.Table {
        Self(
            items: items,
            nameDetails: nameDetails,
            valuesDetails: valuesDetails,
            nameStyleTransform: nameStyleTransform,
            valueStyleTransform: valueStyleTransform
        )
    }
}
