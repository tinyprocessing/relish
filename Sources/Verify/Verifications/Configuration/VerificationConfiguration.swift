import Foundation

struct VerificationConfiguration {
    var fileSize: FileSize
    var projectIntegrity: ProjectIntegrity

    struct FileSize: Codable {
        var exceptions: Exceptions
        var size: Size

        struct Exceptions: Codable {
            var fileExtensions: [String] = []
            var files: [String] = []
        }

        struct Size: Codable {
            var limit: Int64
            var fileExtensions: [FileExtension] = []

            struct FileExtension: Codable {
                var name: String
                var limit: Int64
            }
        }
    }

    struct ProjectIntegrity {
        var pluginImportVerification = PluginImportVerification()

        struct PluginImportVerification {
            var apiTargets: Set<String> = []
            var targetExceptions: [TargetException] = []

            struct TargetException {
                var target: String
                var exceptions: Set<String>
            }
        }
    }
}

// MARK: - RawConfigurable

extension VerificationConfiguration: RelishRawConfigurable {
    typealias RawConfiguration = RawVerificationConfiguration

    init(from rawConfig: RawVerificationConfiguration) throws {
        try self.init(
            fileSize: VerificationConfiguration.FileSize(
                exceptions: FileSize.Exceptions(
                    fileExtensions: rawConfig.fileSize?.exceptions?.fileExtensions ?? [],
                    files: rawConfig.fileSize?.exceptions?.files ?? []
                ),
                size: FileSize.Size(
                    limit: rawConfig.fileSize?.size.limit ?? 500,
                    fileExtensions: rawConfig.fileSize?.size.fileExtensions.map { fileExtension in
                        FileSize.Size.FileExtension(name: fileExtension.name, limit: fileExtension.limit)
                    } ?? []
                )
            ),
            projectIntegrity: rawConfig.projectIntegrity.map {
                try VerificationConfiguration.ProjectIntegrity(from: $0)
            } ?? ProjectIntegrity()
        )
    }
}

extension VerificationConfiguration.ProjectIntegrity: RelishRawConfigurable {
    typealias RawConfiguration = RawVerificationConfiguration.ProjectIntegrity

    init(from rawConfig: RawVerificationConfiguration.ProjectIntegrity) throws {
        self.init(pluginImportVerification: PluginImportVerification(
            apiTargets: Set(rawConfig.pluginImportVerification?.apiTargets ?? []),
            targetExceptions:
            rawConfig.pluginImportVerification?.targetExceptions?.map {
                PluginImportVerification.TargetException(target: $0.target, exceptions: Set($0.exceptions))
            } ?? []
        ))
    }
}

// MARK: - RawVerificationConfiguration

struct RawVerificationConfiguration: RelishRawConfiguration {
    static let fileName = "Verifications"
    static let schemaFileName = "verifications.schema"

    var projectIntegrity: ProjectIntegrity?
    var fileSize: FileSize?
    var duplicate: Duplicate?

    struct ProjectIntegrity: Codable {
        var pluginImportVerification: PluginImportVerification?

        struct PluginImportVerification: Codable {
            var apiTargets: [String]
            var targetExceptions: [TargetException]?

            struct TargetException: Codable {
                var target: String
                var exceptions: [String]
            }
        }
    }

    struct FileSize: Codable {
        var exceptions: Exceptions?
        var size: Size

        struct Exceptions: Codable {
            var fileExtensions: [String]
            var files: [String]
        }

        struct Size: Codable {
            var limit: Int64
            var fileExtensions: [FileExtension]

            struct FileExtension: Codable {
                var name: String
                var limit: Int64
            }
        }
    }

    struct Duplicate: Codable {}
}
