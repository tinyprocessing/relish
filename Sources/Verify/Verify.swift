import ArgumentParser
import Foundation

struct Verify: RelishCommand {
    static let configuration: CommandConfiguration = .init(
        abstract: "Verify changes to workspace!",
        subcommands: [
            PreCommit.self,
            Project.self,
            ProjectSettings.self
        ]
    )

    static let commandName = "relish verify"

    @OptionGroup()
    var options: Relish.Options
}
