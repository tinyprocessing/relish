import Foundation

extension URL {
    /// A collection of the common image asset file extensions.
    static let imageAssetExtensions: Set<String> = ["png", "jpeg", "jpg", "pdf", "svg"]

    /// Returns the relative path from the current directory to self.
    var relativePathFromCurrentDirectory: String? {
        relativePath(from: URL(fileURLWithPath: ".").absoluteURL)
    }

    /// Whether the file is a reference to an image asset
    var isImageAsset: Bool {
        Self.imageAssetExtensions.contains(pathExtension)
    }

    /// Returns the relative path from a base url to self.
    ///
    /// - Parameter base: The base url to use when deriving the relative path.
    /// - Returns: The relative path from a base url to self, or nil if one cannot be found.
    func relativePath(from base: URL) -> String? {
        // Ensure that both URLs represent files and are absolute paths.
        guard isFileURL && base.isFileURL,
              baseURL == nil && base.baseURL == nil
        else { return nil }

        // Ensure urls are converted to relative paths.
        let destinationComponents = standardizedFileURL.pathComponents
        let baseComponents = base.standardizedFileURL.pathComponents

        // Find number of common path components
        var commonPathCount = 0
        while commonPathCount < destinationComponents.count &&
            commonPathCount < baseComponents.count &&
            destinationComponents[commonPathCount] == baseComponents[commonPathCount] {
            commonPathCount += 1
        }

        // Build relative path
        var relativeComponents = Array(repeating: "..", count: baseComponents.count - commonPathCount)
        relativeComponents.append(contentsOf: destinationComponents[commonPathCount...])
        return relativeComponents.joined(separator: "/")
    }

    /// Returns whether self is an ancestor of another URL.
    ///
    /// - Author: [Stack Overflow](https://stackoverflow.com/questions/43193772)
    /// - Parameter child: A potential estranged child.
    /// - Returns: A Boolean value indicating whether `self` is a parent of `child`.
    func isAncestor(of possibleChildURL: URL) -> Bool {
        guard isFileURL && possibleChildURL.isFileURL else { return false }

        let ancestorComponents: [String] = canonicalized().pathComponents
        let childComponents: [String] = possibleChildURL.canonicalized().pathComponents

        return ancestorComponents.count < childComponents.count
            && !zip(ancestorComponents, childComponents).contains(where: !=)
    }

    /// Returns whether self is the direct parent of another URL.
    ///
    /// - Author: [Stack Overflow](https://stackoverflow.com/questions/43193772)
    /// - Parameter child: A potential estranged child.
    /// - Returns: A Boolean value indicating whether `self` is a direct parent of `child`.
    func isParent(of child: URL) -> Bool {
        let ancestorComponents: [String] = canonicalized().pathComponents
        let childComponents: [String] = child.canonicalized().pathComponents

        return ancestorComponents.count + 1 == childComponents.count
            && !zip(ancestorComponents, childComponents).contains(where: !=)
    }

    /// Returns the standardized URL while also resolving any symbolic links.
    func canonicalized() -> URL {
        standardizedFileURL.resolvingSymlinksInPath()
    }
}

extension Array where Element == URL {
    func closestAncestor(to childURL: URL) -> URL? {
        guard filter({ $0.isAncestor(of: childURL) }).isNotEmpty else {
            return nil
        }

        let childComponents: [String] = childURL.canonicalized().pathComponents

        let sorted = sorted { lhs, rhs in
            let lhsComponents = lhs.canonicalized().pathComponents
            let lhsDifferenceCount = lhsComponents.difference(from: childComponents).count

            let rhsComponents = rhs.canonicalized().pathComponents
            let rhsDifferenceCount = rhsComponents.difference(from: childComponents).count

            return lhsDifferenceCount < rhsDifferenceCount
        }

        return sorted.first
    }
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}
