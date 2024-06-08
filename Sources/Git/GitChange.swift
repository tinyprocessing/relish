import Foundation

// In the following table, these three classes are shown in separate sections, and these characters are used for X and Y
// fields for the first two sections that show tracked paths:
//
//       •   ' ' = unmodified
//       •   M = modified
//       •   A = added
//       •   D = deleted
//       •   R = renamed
//       •   C = copied
//       •   U = updated but unmerged
//
//           X          Y     Meaning
//           -------------------------------------------------
//                    [AMD]   not updated
//           M        [ MD]   updated in index
//           A        [ MD]   added to index
//           D                deleted from index
//           R        [ MD]   renamed in index
//           C        [ MD]   copied in index
//           [MARC]           index and work tree matches
//           [ MARC]     M    work tree changed since index
//           [ MARC]     D    deleted in work tree
//           [ D]        R    renamed in work tree
//           [ D]        C    copied in work tree
//           -------------------------------------------------
//           D           D    unmerged, both deleted
//           A           U    unmerged, added by us
//           U           D    unmerged, deleted by them
//           U           A    unmerged, added by them
//           D           U    unmerged, deleted by us
//           A           A    unmerged, both added
//           U           U    unmerged, both modified
//           -------------------------------------------------
//           ?           ?    untracked
//           !           !    ignored
//           -------------------------------------------------

struct GitChange {
    enum Descriptor: String {
        case unmodified = " "
        case modified = "M"
        case added = "A"
        case deleted = "D"
        case renamed = "R"
        case copied = "C"
        case updatedButUnmerged = "U"
        case untracked = "?"
        case ignored = "!"
    }

    let ourDescriptor: Descriptor
    let theirDescriptor: Descriptor
    let fileURL: URL

    var fileName: String { fileURL.deletingPathExtension().lastPathComponent }
    var fileExtension: String { fileURL.pathExtension }

    var isStaged: Bool {
        return ourDescriptor != .unmodified && theirDescriptor == .unmodified
    }

    var isTracked: Bool {
        return !(ourDescriptor == .untracked && theirDescriptor == .untracked)
    }

    /// FIXME: `ourDescriptor` and `theirDescriptor` may contain multiple descriptors. e.g. A file may be renamed AND
    /// modified. The current code only supports parsing a single descriptor. We should probably consider making the
    /// descriptors an option set.
    init?(_ string: String) {
        guard let ourDescriptor = Descriptor(rawValue: String(string.prefix(1))) else {
            return nil
        }

        guard let theirDescriptor = Descriptor(rawValue: String(string[1])) else {
            return nil
        }

        guard let fileURL = Self.fileURL(from: string) else {
            return nil
        }

        self.ourDescriptor = ourDescriptor
        self.theirDescriptor = theirDescriptor
        self.fileURL = fileURL
    }

    /// A regex for capturing the new location of a file. e.g. `R  SomeFile.swift -> NewLocation/SomeFile.swift`
    ///
    /// The single capture group contains the new location of the file.
    private static let renameRegex = try! NSRegularExpression(pattern: #".*-> (.*)"#)

    private static func fileURL(from string: String) -> URL? {
        if let renamedFileURL = parseRenamedFileURL(from: string) {
            return renamedFileURL
        } else {
            return URL(string: string.removing(prefix: String(string.prefix(3))))
        }
    }

    private static func parseRenamedFileURL(from string: String) -> URL? {
        let match = Self.renameRegex.firstFormattedMatch(
            in: string,
            range: string.startIndex..<string.endIndex
        )?.captureGroups.first

        return match.flatMap { URL(string: $0) }
    }
}
