import Foundation

enum DirectoryError: Error {
    case failedToCreateFile
    case failedToCreateDirectory
    case failedToLocateRelativePath
}

class Directory {
    static let root = "/"
    static let relishPlist = "Relish.plist"

    private(set) var projectRoot = ""

    private let fileManager: FileManager
    private lazy var previousPath: String = currentPath

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        projectRoot = fileManager.currentDirectoryPath
    }

    var homePath: URL {
        fileManager.homeDirectoryForCurrentUser
    }

    var currentPath: String {
        fileManager.currentDirectoryPath
    }

    func advance(toDirectory directory: String) {
        previousPath = currentPath

        let newPath = currentPath + "/" + directory

        fileManager.changeCurrentDirectoryPath(newPath)
    }

    func goBack(numberOfDirectories: Int = 1) {
        previousPath = currentPath

        let newPath = currentPath.split(separator: "/").dropLast(numberOfDirectories).joined(separator: "/")

        fileManager.changeCurrentDirectoryPath(newPath)
    }

    func changeTo(path: String) {
        previousPath = currentPath

        fileManager.changeCurrentDirectoryPath(path)
    }

    func changeToRepoRoot() throws {
        try changeTo(path: repoRoot())
    }

    func returnToPreviousDirectory() {
        let path = currentPath
        defer {
            previousPath = path
        }

        fileManager.changeCurrentDirectoryPath(previousPath)
    }

    func fileExists(at path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    func url(forFileAtPath path: String) -> URL? {
        guard fileExists(at: path) else { return nil }

        return URL(fileURLWithPath: path)
    }

    func filesInCurrentDirectory(withExtension fileExtension: String) throws -> [URL] {
        return try filesIn(
            directory: currentPath,
            withExtension: fileExtension
        )
    }

    func filesIn(directory path: String, withExtension fileExtension: String) throws -> [URL] {
        let files = try fileManager.contentsOfDirectory(atPath: path)

        return files
            .compactMap { path in
                URL(string: path)
            }
            .filter { url in
                url.pathExtension == fileExtension.removing(prefix: ".")
            }
    }

    func findAllFiles(matching regex: NSRegularExpression) throws -> [URL] {
        try findAllFiles(at: URL(fileURLWithPath: currentPath), matching: regex)
    }

    func findAllFiles(at url: URL, matching regex: NSRegularExpression) throws -> [URL] {
        let resourceKeys: [URLResourceKey] = [.nameKey, .isDirectoryKey]
        guard let enumerator = fileManager
            .enumerator(
                at: url,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
        else { return [] }

        var urls: [URL] = []

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))

            guard let name = resourceValues.name,
                  !(resourceValues.isDirectory ?? false)
            else {
                continue
            }

            if regex.firstFormattedMatch(in: name, range: name.startIndex..<name.endIndex) != nil {
                urls.append(fileURL)
            }
        }

        return urls
    }

    func renameFile(fromPath: String, toPath: String, isDirectory: Bool) throws {
        guard fileManager.fileExists(atPath: fromPath) else {
            if isDirectory {
                try createDirectory(at: toPath)
            } else {
                try createFile(at: toPath)
            }

            return
        }

        try fileManager.moveItem(atPath: fromPath, toPath: toPath)
    }

    func createDirectory(at path: String, shouldRecreate: Bool = false) throws {
        let url = URL(fileURLWithPath: path)
        try fileManager.createDirectory(at: url, shouldRecreate: shouldRecreate)
    }

    func deleteIfExists(at path: String) throws {
        guard fileManager.fileExists(atPath: path) else {
            return
        }
        try fileManager.removeItem(atPath: path)
    }

    func directoryContents(atPath path: String) throws -> [String] {
        return try fileManager.contentsOfDirectory(atPath: path)
    }

    func directoryContentURLs(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]? = nil
    ) throws -> [URL] {
        return try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: keys)
    }

    func repoRoot() throws -> String {
        guard !(try directoryContents(atPath: currentPath)
            .contains(where: { $0.hasSuffix(Self.relishPlist) }))
        else {
            return currentPath
        }

        var path = URL(fileURLWithPath: currentPath)

        while path.absoluteString != "/" {
            let resourceInfo = try path.resourceValues(forKeys: [.isDirectoryKey, .parentDirectoryURLKey])

            guard let parent = resourceInfo.parentDirectory?.path.removingPercentEncoding else {
                return path.absoluteString
            }

            let contents = try directoryContents(atPath: parent)

            if contents.contains(where: { $0.hasSuffix(Self.relishPlist) }) {
                return parent
            }

            path = URL(fileURLWithPath: parent)
        }

        return path.absoluteString
    }

    func isFileInRootDirectory(_ url: URL) throws -> Bool {
        return try repoRootURL.isParent(of: url)
    }

    func isChildOfDocsDirectory(_ url: URL) throws -> Bool {
        return try docsDirectory.isAncestor(of: url)
    }

    func isChildOfConfigurationsDirectory(_ url: URL) throws -> Bool {
        return try configurationsDirectory.isAncestor(of: url)
    }

    func isChildBinaryDependencySpecificationDirectory(_ url: URL) throws -> Bool {
        return try binaryDependencySpecificationDirectory.isAncestor(of: url)
    }

    func relativePathFromRepoRoot(_ url: URL) throws -> String {
        guard let path = try url.relativePath(from: repoRootURL) else {
            throw DirectoryError.failedToLocateRelativePath
        }

        return path
    }

    func isDescendentOfLintableDirectory(_ url: URL) throws -> Bool {
        let lintableDirectories = try [
            marketsDirectory,
            pluginsDirectory,
            modulesDirectory,
            platformDirectory
        ]

        return lintableDirectories.contains(where: { $0.isAncestor(of: url) })
    }

    func scriptsDirectory() throws -> String {
        return try "\(repoRoot())/scripts"
    }

    func createFile(at path: String) throws {
        guard fileManager.createFile(
            atPath: path,
            contents: nil,
            attributes: nil
        )
        else {
            throw DirectoryError.failedToCreateFile
        }
    }
}

// MARK: - Locations

extension Directory {
    /// Returns the URL for the root of the repository that this package is located in.
    var repoRootURL: URL {
        get throws {
            try URL(fileURLWithPath: repoRoot(), isDirectory: true)
        }
    }

    var docsDirectory: URL {
        get throws {
            try URL(fileURLWithPath: repoRoot(), isDirectory: true).appendingPathComponent("docs", isDirectory: true)
        }
    }

    var configurationsDirectory: URL {
        get throws {
            try URL(fileURLWithPath: repoRoot(), isDirectory: true)
                .appendingPathComponent("Configuration", isDirectory: true)
        }
    }

    var binaryDependencySpecificationDirectory: URL {
        get throws {
            try URL(fileURLWithPath: repoRoot(), isDirectory: true)
                .appendingPathComponent("BinaryDependencySpecification", isDirectory: true)
        }
    }

    var configurationFileURL: URL {
        get throws {
            try repoRootURL.appendingPathComponent(Self.relishPlist, isDirectory: false)
        }
    }

    var ciXcconfigFileURL: URL {
        get throws {
            try repoRootURL.appendingPathComponent("BuildSupport/CI.xcconfig")
        }
    }

    var packageManifestURL: URL {
        get throws {
            try repoRootURL.appendingPathComponent("Platform/relishPlatform", isDirectory: true)
        }
    }

    var marketsDirectory: URL {
        get throws {
            try repoRootURL.appendingPathComponent("markets")
        }
    }

    var pluginsDirectory: URL {
        get throws {
            try URL(fileURLWithPath: repoRoot(), isDirectory: true).appendingPathComponent("Plugins", isDirectory: true)
        }
    }

    var modulesDirectory: URL {
        get throws {
            try URL(fileURLWithPath: repoRoot(), isDirectory: true).appendingPathComponent("Modules", isDirectory: true)
        }
    }

    var platformDirectory: URL {
        get throws {
            try URL(fileURLWithPath: repoRoot(), isDirectory: true)
                .appendingPathComponent("Platform", isDirectory: true)
        }
    }

    var swiftFormatConfigFileURL: URL {
        get throws {
            try repoRootURL.appendingPathComponent(".swiftformat")
        }
    }

    var relishCLIDirectory: URL {
        get throws {
            try repoRootURL.appendingPathComponent("Platform/relishCLI", isDirectory: true)
        }
    }

    var mintfileURL: URL {
        get throws {
            try repoRootURL.appendingPathComponent("Mintfile", isDirectory: false)
        }
    }
}
