import Foundation

/// A type with a richly formatted textual representation.
protocol CustomTextConvertible: CustomStringConvertible {
    /// A richly formatted textual representation of this instance.
    var textDescription: [TextualElement] { get }
}

extension CustomTextConvertible {
    var description: String {
        consoleDescription
    }

    var markdownDescription: String {
        TextFormatter.markdownString(from: textDescription)
    }

    var consoleDescription: String {
        TextFormatter.consoleMessageString(from: textDescription)
    }
}
