import Foundation

struct LargeFileVerification: ChangeVerification {
    let name = "Large Files"
    let description = """
    Verifies that any new or modified files are not too large.
    """

    var configuration: VerificationConfiguration.FileSize

    func verify(context: ChangeContext) async throws {
        let largeFiles = try context.files
            .filter { $0.status == .added || $0.status == .modified }
            .compactMap { try File(fileURL: $0.url) }
            .filter { isFileTooFat($0) }

        guard largeFiles.isNotEmpty else {
            return
        }

        try throwFatal(Failure(files: largeFiles, configuration: configuration))
    }

    private func isFileExempt(_ file: File) -> Bool {
        configuration.exceptions.files.contains(file.filePath)
            || configuration.exceptions.fileExtensions.contains(file.fileExtension)
    }

    private func isFileTooFat(_ file: File) -> Bool {
        if let fileExtension = configuration.size.fileExtensions.first(where: { $0.name == file.fileExtension }) {
            return file.fileSizeKB > fileExtension.limit
        } else {
            return file.fileSizeKB > configuration.size.limit
        }
    }
}

extension LargeFileVerification {
    struct File {
        let filePath: String
        let fileExtension: String
        let fileSize: UInt64

        var fileSizeKB: UInt64 {
            fileSize >> 10
        }

        var fileSizeDescription: String {
            ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
        }

        var description: String {
            "\(fileSizeDescription) - \(filePath)"
        }

        init?(fileURL: URL) throws {
            guard let filePath = fileURL.standardizedFileURL.relativePathFromCurrentDirectory else {
                return nil
            }

            fileExtension = fileURL.pathExtension
            self.filePath = filePath
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            fileSize = attributes[.size] as? UInt64 ?? 0
        }
    }
}

extension LargeFileVerification {
    struct Failure: ChangeVerificationFailureProtocol {
        static let assetGuidelinesURLString = """
        <your link for guidlines>
        """

        let files: [File]
        let configuration: VerificationConfiguration.FileSize

        func issues() -> [ChangeVerificationFailure.Issue] {
            [
                ChangeVerificationFailure.Issue(
                    description: .customDescription {
                        [
                            [.body(
                                """
                                One or more files have been added that exceed a file size limit. If this is an asset, \
                                please work with UX or your asset provider to better optimize the asset.

                                If this asset is already optimized or the file requires an exception, add the file to \
                                the exception list in `~/relish/Verifications.json` under `fileSize.exceptions.files`.

                                See the [Asset Guidelines](\(Self.assetGuidelinesURLString)) documentation for more \
                                information.

                                """
                            )],
                            configuration.size.textDescription,
                            [.body("")],
                            [.list(
                                withHeading: "Assets exceeding the size limit",
                                items: files.map { $0.description }
                            )]
                        ].flatMap { $0 }
                    }
                )
            ]
        }
    }
}

extension VerificationConfiguration.FileSize.Size: CustomTextConvertible {
    var textDescription: [TextualElement] {
        [
            .body("Default size limit: \(limit) KiB."),
            fileExtensions.isEmpty ? nil : .list(
                withHeading: "File extensions",
                items: fileExtensions.map { "\($0.name): \($0.limit) KiB" }
            )
        ].compactMap { $0 }
    }
}
