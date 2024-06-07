import Foundation

/// Protocol describing the requirements of a ``ChangeVerification/Failure``.
protocol ChangeVerificationFailureProtocol {
    /// The ``ChangeVerificationFailure/Issue``s associated with the failure.
    ///
    /// - Returns: An array of ``ChangeVerificationFailure/Issue`` objects.
    func issues() -> [ChangeVerificationFailure.Issue]
}

/// Verifies that a set of changes are valid.
protocol ChangeVerification {
    associatedtype Failure: ChangeVerificationFailureProtocol

    /// A descriptive name of the verification.
    var name: String { get }

    /// A simple description of what the ``ChangeVerification`` is verifying.
    var description: String { get }

    /// Verifies a set of changes using the change context.
    ///
    /// A ``ChangeVerificationFailure`` should be thrown if the verification fails. If a different error is thrown, the
    /// verification itself will be treated as a failure (i.e. failed to run verification).
    ///
    ///
    /// - Parameter context: The context of the changes to verify.
    func verify(context: ChangeContext) async throws
}

extension ChangeVerification {
    func throwFatal(_ failure: Failure) throws -> Never {
        throw ChangeVerificationFailure(
            issues: failure.issues(),
            severity: .fatal,
            verification: self
        )
    }

    func throwWarning(_ failure: Failure) throws -> Never {
        throw ChangeVerificationFailure(
            issues: failure.issues(),
            severity: .warning,
            verification: self
        )
    }
}

/// An object representing a set of changes.
enum ChangeContext {
    case commit(files: [ChangeFile])
    /// Will be used to move some of the pre-commit verifications to pre-push
    case push
    case pullRequest(files: [ChangeFile], author: String, number: Int)

    /// A collection of changed files to verify.
    var files: [ChangeFile] {
        switch self {
        case .commit(let files):
            return files
        case .push:
            return []
        case .pullRequest(let files, _, _):
            return files
        }
    }
}

/// A file that has been changed in some way.
struct ChangeFile {
    /// An absolute file URL to the changed file.
    var url: URL

    /// The status of the staged changed file.
    var status: Status

    /// The (git) unstaged status of the file.
    ///
    /// If the file originates from a pull request, the unchanged status will always be
    /// ``Status-swift.enum/unchanged``.
    var unstagedStatus: Status

    /// The change status of the file.
    enum Status: String, Codable {
        /// The file was added. Git status 'A'.
        case added

        /// The file was deleted. Git status 'D'.
        case deleted

        /// The file was copied. Git status 'C'.
        case copied

        /// The file's type was changed. Git status 'T'.
        case changed

        /// The file's contents were changed. Git status 'M'.
        case modified

        /// The file was renamed. Git status 'R'.
        ///
        /// FIXME: A renamed `status` may also indicate `modification`.
        case renamed

        /// The file has not been modified.
        ///
        /// This often occurs when the file is modified and there are no unstaged changes.
        case unchanged

        /// Relevant for local changes only
        case updatedButUnmerged
    }
}

// MARK: - Helpers

extension ChangeContext {
    /// Returns all of the `.swift` files in ``files``.
    var swiftFiles: [ChangeFile] {
        files.filter { $0.url.pathExtension == "swift" }
    }

    /// The files where the name of the file matches the pattern.
    ///
    /// - Parameter pattern: The pattern to match against the name of the file.
    /// - Returns: The files satisfying the pattern.
    func files(nameMatching pattern: NSRegularExpression) -> [ChangeFile] {
        return files.filter { file in
            pattern.firstMatch(
                in: file.url.lastPathComponent,
                options: [],
                range: NSRange(location: 0, length: file.url.lastPathComponent.utf16.count)
            ) != nil
        }
    }
}

extension ChangeFile {
    /// A Boolean value that indicates the status is a type of modification (i.e. update), but not deleted.
    ///
    /// > Important: If the `unstagedStatus` is deleted, `false` is returned.
    var isUpdated: Bool {
        guard unstagedStatus != .deleted else {
            return false
        }

        switch status {
        case .updatedButUnmerged, .copied, .changed, .added, .modified, .renamed:
            return true
        case .deleted, .unchanged:
            return false
        }
    }
}
