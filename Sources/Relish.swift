import ArgumentParser
import Foundation

// MARK: - Relish

@main
struct Relish: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A swift command-line tool for managing relish projects",
        version: "1.0.0",
        subcommands: [
            Format.self,
            Environment.self,
            Verify.self,
            Sort.self
        ]
    )

    struct Options: ParsableArguments {
        @Flag(name: .shortAndLong, help: "Determines whether verbose logging is enabled.")
        var verbose = false

        @Option(name: .long,
                help: ArgumentHelp("The command will only execute if in the specified environment.",
                                   visibility: .hidden))
        var requiredEnvironment: CommandEnvironment?
    }

    static func load<Configuration: RelishRawConfigurable>(
        _ type: Configuration.Type
    ) throws -> Configuration where Configuration.RawConfiguration: RelishRawConfiguration {
        let homeDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        let fileURL = homeDirectoryURL
            .appendingPathComponent(".config/relish/\(Configuration.RawConfiguration.fileName.lowercased()).json")
        let json = try JSONDecoder().decode(Configuration.RawConfiguration.self, from: Data(contentsOf: fileURL))
        return try Configuration(from: json)
    }
}

// MARK: - CommandEnvironment

enum CommandEnvironment: String, ExpressibleByArgument, CaseIterable {
    case ci
    case local

    var defaultValueDescription: String {
        switch self {
        case .ci:
            return "Continuous integration environment"
        case .local:
            return "Local dev environment."
        }
    }
}
