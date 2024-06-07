import ArgumentParser
import Foundation

struct Format: RelishCommand {
    static let configuration: CommandConfiguration = .init(
        abstract: "Formatting of Swift code",
        subcommands: [
            Format.Path.self
        ],
        defaultSubcommand: Format.Path.self
    )

    static let commandName = "relish format"

    @OptionGroup()
    var options: Relish.Options
}

/// An error while working with Format.
struct FormatError: Error {
    let message: String
}
