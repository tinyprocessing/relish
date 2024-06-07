import ArgumentParser
import Foundation

extension Format {
    struct Path: RelishCommand {
        var isVerbose: Bool { options.verbose }

        static let commandName = "relish format path"

        static let discussionText = """
        The path can point to either a single Swift file or a directory of files.
        It can be either be absolute, or relative to the current directory.
        The quotes around the path are optional, but if the path contains spaces \
        then you either need to use quotes, or escape each space with \\.
        You may include multiple paths separated by spaces.
        """

        @OptionGroup()
        var options: Relish.Options

        static let configuration: CommandConfiguration = .init(
            commandName: "path",
            abstract: "Format a single Swift file or folder.",
            usage: "format path \"path/to/something\" (-v)",
            discussion: Self.discussionText
        )

        @Argument
        var path: String

        var console: Console<NeverThrows> {
            isVerbose ? Logger.verboseConsole : Logger.console
        }

        var formatCommand: String { "swiftformat --config ~/.relishformat \(path)" }

        func runCommand() async throws {
            console.log(.step("Formatting Swift file(s): \(path)"))
            defer {
                console.log(.info("Finished formatting."))
            }
            console.log(.info("Formatting \(path)"))
            let shell = Shell(command: formatCommand)
            do {
                try await shell.process()
            } catch {
                console.log(.failure("Formatting error: \(error.localizedDescription)"))
                return
            }
        }
    }
}
