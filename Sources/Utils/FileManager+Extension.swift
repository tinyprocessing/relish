import Foundation

extension FileManager {
    /// - Parameter shouldRecreate: If the folder already exists, pass `true` to recreate
    /// the directory, otherwise, it will return and print an error when try to create the
    /// directory if one exists already..
    func createDirectory(at url: URL, shouldRecreate: Bool = false) throws {
        if shouldRecreate && fileExists(atPath: url.path) {
            try removeItem(at: url)
        }

        try createDirectory(at: url, withIntermediateDirectories: true)
    }

    /// Returns all of the files with the `pathExtension` in the provided `directory`.
    func files(withPathExtension pathExtension: String, in directory: URL) -> [URL] {
        files(in: directory) { $0.pathExtension == pathExtension }
    }

    func files(in directory: URL = URL(fileURLWithPath: "."), matching: (URL) -> Bool) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
        else {
            return []
        }

        var files: [URL] = []

        for case let fileURL as URL in enumerator where matching(fileURL) {
            files.append(fileURL)
        }

        return files
    }

    /// Creates a **unique** temporary directory and returns the URL of it.
    func createTemporaryDirectory() throws -> URL {
        let directory = URL(
            fileURLWithPath: "\(NSTemporaryDirectory())/\(UUID().uuidString)",
            isDirectory: true
        )

        try createDirectory(atPath: directory.path, withIntermediateDirectories: true)

        return directory
    }

    /// Creates and returns a **unique** temporary file URL.
    func createTemporaryFileURL() -> URL {
        URL(
            fileURLWithPath: "\(NSTemporaryDirectory())/\(UUID().uuidString)",
            isDirectory: false
        )
    }

    /// Replaces the item at `originalURL` with the item located at `newURL`.
    func replaceItem(at originalURL: URL, with newURL: URL) throws {
        do {
            try removeItem(at: originalURL)
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            // ignore missing file error
        }
        try copyItem(atPath: newURL.path, toPath: originalURL.path)
    }

    func isDirectory(at url: URL) -> Bool? {
        var isDir: ObjCBool = false
        if fileExists(atPath: url.path, isDirectory: &isDir) {
            return isDir.boolValue
        }
        return nil
    }
}
