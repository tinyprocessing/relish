import ArgumentParser
import Foundation

struct Setup: RelishCommand {
    var isVerbose: Bool { options.verbose }

    static let configuration: CommandConfiguration = .init(
        abstract: "Setup the environment (download dependencies, initialize githooks)"
    )

    static let commandName = "relish environment setup"

    @Option(name: .shortAndLong, help: "The path of the directory that contains the xcode project.")
    var path: String = FileManager.default.currentDirectoryPath

    @Flag(name: .shortAndLong)
    var update = false

    @Flag(name: .long)
    var useSubmodules = false

    @OptionGroup()
    var options: Relish.Options

    var console: Console<NeverThrows> {
        isVerbose ? Logger.verboseConsole : Logger.console
    }

    func runCommand() async throws {
        let commands = [
            "brew install swiftformat"
        ]

        for command in commands {
            console.log(.step("Working on \(command)"))
            let shell = Shell(command: command)
            do {
                try await shell.process()
            } catch {
                console.log(.failure("Installing error: \(error.localizedDescription)"))
                return
            }
        }
    }
}
