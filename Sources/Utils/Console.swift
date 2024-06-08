import ArgumentParser
import Foundation

protocol DiagnosticLog: Encodable {
    var event: String { get }
    var logIdentifier: String { get }
    var platform: String { get }
}

protocol ThrowableError: LocalizedError {
    var consoleMessage: String { get }
}

extension ThrowableError {
    public var errorDescription: String? {
        consoleMessage
    }
}

typealias NeverThrows = Never
extension Never: ThrowableError {
    var consoleMessage: String { "" }
}

struct Console<ErrorType: ThrowableError> {
    enum Log {
        case command(String)
        case warn(String)
        case failure(String)
        case success(String)
        case message(String)
        case step(String)
        case info(String)

        case buildWarning(String)
        case buildError(String)
    }

    let isVerbose: Bool
    let formatter: ASCIIFormatter

    init(isVerbose: Bool, formatter: ASCIIFormatter = GlobalASCIIFormatter()) {
        self.isVerbose = isVerbose
        self.formatter = formatter
    }

    func log(_ log: Log) {
        switch log {
        case .command(let message):
            print("🚀 " + message.applyingAsciiFormatting(.greenBold, formatter: formatter))

        case .warn(let message):
            print("⚠️ " + message.applyingAsciiFormatting(.yellow, formatter: formatter))

        case .failure(let message):
            print("❌ " + message.applyingAsciiFormatting(.redBold, formatter: formatter))

        case .success(let message):
            print("🟢 " + message.applyingAsciiFormatting(.cyan, formatter: formatter))

        case .message(let message):
            print(message)

        case .step(let message):
            print("🔹 " + message.applyingAsciiFormatting(.cyan, formatter: formatter))

        case .info(let message):
            printIfVerbose(isVerbose, "    - \(message)".applyingAsciiFormatting(.white, formatter: formatter))

        case .buildWarning(let message):
            // `warning` must be the first part of the string to generate a warning in Xcode's build system.
            print("warning: ⚠️" + message)

        case .buildError(let message):
            // `error` must be the first part of the string to generate a warning in Xcode's build system.
            print("error: ❌:" + message)
        }
    }

    func logError(_ error: ErrorType, file: StaticString = #file, line: Int = #line) {
        log(throwable: error, file: file, line: line)
    }

    func log(throwable: ThrowableError, file: StaticString = #file, line: Int = #line) {
        print(
            """
            🛑 ERROR! 🛑:
               - Message: \(throwable.consoleMessage)
               - File: \(file)
               - Line: \(line)
            """.applyingAsciiFormatting(.red, formatter: formatter)
        )
    }

    func throwError(_ error: ErrorType, file: StaticString = #file, line: Int = #line) throws -> Never {
        logError(error, file: file, line: line)
        throw error
    }

    func dump<Log: Encodable>(log: Log) {
        self.log(.step("Dumping Log:"))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(log),
              let string = String(data: data, encoding: .utf8)
        else { return }

        print(string)
    }
}

extension Console {
    func step(_ message: String) {
        log(.step(message))
    }

    func success(_ message: String) {
        log(.success(message))
    }

    func verbose(_ message: String) {
        log(.info(message))
    }

    func warn(_ message: String) {
        log(.warn(message))
    }

    func failure(_ message: String) {
        log(.failure(message))
    }
}

enum Logger {
    static let verboseConsole = Console<NeverThrows>(isVerbose: true)
    static let console = Console<NeverThrows>(isVerbose: false)
}
