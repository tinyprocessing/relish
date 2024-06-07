import ArgumentParser
import Foundation

struct Environment: RelishCommand {
    static let configuration: CommandConfiguration = .init(
        abstract: "Deal with setting up and tearing down the projects environment (download dependencies, clean cache, etc)",
        subcommands: [Setup.self]
    )

    static let commandName = "relish environment"

    @OptionGroup()
    var options: Relish.Options
}
