import Foundation
import JSONSchema

struct JSONSchemaValidator {
    var schemaJSON: [String: Any]

    func verify(_ fileURL: URL) throws -> Result<Void, Failure> {
        let fileJSON = try Self.json(from: fileURL)
        let result = try JSONSchema.validate(fileJSON, schema: schemaJSON)

        switch result {
        case .invalid(let errors):
            return .failure(Failure(file: fileURL, errors: errors.map(\.description)))
        case .valid:
            return .success(())
        }
    }

    private static func json(from fileURL: URL) throws -> Any {
        let data = try Data(contentsOf: fileURL, options: .uncached)
        let json = try JSONSerialization.jsonObject(with: data)

        return json
    }

    struct Failure: LocalizedError, CustomTextConvertible {
        var file: URL
        var errors: [String]

        var errorDescription: String? {
            consoleDescription
        }

        var textDescription: [TextualElement] {
            return [
                .list(
                    withHeading: "The file \(file.lastPathComponent) has the following issues",
                    items: errors.map {
                        .standardText($0)
                    }
                )
            ]
        }
    }
}

extension JSONSchemaValidator {
    struct ParseError: LocalizedError {
        var errorDescription: String?
    }

    init(schemaFileURL: URL) throws {
        guard let schemaJSON = try Self.json(from: schemaFileURL) as? [String: Any] else {
            throw ParseError(errorDescription: "Failed to load schema file")
        }

        self.schemaJSON = schemaJSON
    }
}
