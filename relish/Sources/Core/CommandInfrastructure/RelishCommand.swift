import ArgumentParser
import Foundation

protocol RelishCommand: AsyncParsableCommand {
    static var commandName: String { get }

    var options: Relish.Options { get }

    var allowedIntercepters: [InterceptorType] { get }

    func runCommand() async throws
}

extension RelishCommand {
    static var defaultInterceptors: [InterceptorType] {
        return [.automaticUpdating]
    }

    var allowedIntercepters: [InterceptorType] {
        return Self.defaultInterceptors
    }

    func runCommand() async throws {
        // Default implementation does nothing
    }

    func run() async throws {
        do {
            let console = Console<NeverThrows>(isVerbose: options.verbose)

            let duration = try await ContinuousClock().measure {
                try await _run()
            }

            let durationDescription = duration.formatted(.units(allowed: [.seconds, .milliseconds]))
            console.log(.step("\(Self.commandName) took \(durationDescription) to execute."))

            Self.exit()
        } catch {
            Self.exit(withError: error)
        }
    }

    private func _run() async throws {
        let console = Console<NeverThrows>(isVerbose: options.verbose)

        guard options.requiredEnvironment?.canExecuteInCurrentEnvironment ?? true else {
            console.log(.step(
                """
                Skipping \(Self.commandName) because command is set to run only in \
                environment=\(options.requiredEnvironment!).
                """
            ))
            return
        }

        console.log(.command("Running `\(Self.commandName)`..."))
        try await runCommand()
    }

    func logIfVerbose(_ value: String) {
        Console<NeverThrows>(isVerbose: options.verbose).log(.info(value))
    }
}

extension CommandEnvironment {
    fileprivate var canExecuteInCurrentEnvironment: Bool {
        switch self {
        case .ci: return ProcessInfo.processInfo.isJenkinsUser
        case .local: return !ProcessInfo.processInfo.isJenkinsUser
        }
    }
}
