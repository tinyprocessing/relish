import Foundation

enum InterceptorType: CustomStringConvertible {
    case automaticUpdating

    var description: String {
        switch self {
        case .automaticUpdating: return "Automatic Update Interceptor"
        }
    }
}

class CommandInterceptor<Result> {
    let console = Console<NeverThrows>(isVerbose: false)

    var type: InterceptorType {
        fatalError("Developer error, this must be implemented by subclass")
    }

    @discardableResult
    func run(for command: RelishCommand) async throws -> Result {
        fatalError("Developer error, this must be implemented by subclass")
    }

    func shouldIntercept(command: RelishCommand) async throws -> Bool {
        return isAllowed(by: command)
    }

    func isAllowed(by command: RelishCommand) -> Bool {
        guard command.allowedIntercepters.contains(type) else {
            console.log(.step("Skipping \(String(describing: type)) as it is not permitted by this command!"))
            return false
        }

        return true
    }
}
