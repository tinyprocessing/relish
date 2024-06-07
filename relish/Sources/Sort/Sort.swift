import ArgumentParser
import Foundation

protocol Sortable {
    mutating func sort() throws
}

struct Sort: RelishCommand {
    static let configuration: CommandConfiguration = .init(
        abstract: "Sort the project"
    )

    static let commandName = "relish project sort"

    var console: Console<NeverThrows> {
        Logger.console
    }

    @OptionGroup()
    var options: Relish.Options

    func runCommand() async throws {
        console.log(.step("Sort current project"))
        defer {
            console.log(.info("Finished sorting."))
        }
        let shell = Shell(command: "python3 ~/relish/xcodeproj_verifications/_cleanup_projects.py --all --throw")
        do {
            let result = try await shell.process()
            console.log(.success("Sort result: \(result)"))
        } catch {
            console.log(.warn("Sort result: \(error.localizedDescription)"))
            return
        }
    }
}
