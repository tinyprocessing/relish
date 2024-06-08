import Foundation

protocol RelishRawConfigurable {
    associatedtype RawConfiguration: Codable

    init(from rawConfig: RawConfiguration) throws
}

protocol RelishRawConfiguration: Codable {
    static var fileName: String { get }
    static var schemaFileName: String { get }
}

struct RelishConfigurationError: LocalizedError {
    var errorDescription: String?
    init(_ message: String) {
        errorDescription = message
    }
}
