import Foundation

extension String {
    mutating func remove(prefix: String) {
        self = removing(prefix: prefix)
    }

    func removing(prefix: String) -> String {
        guard hasPrefix(prefix)
        else {
            return self
        }

        return String(dropFirst(prefix.count))
    }

    mutating func remove(suffix: String) {
        self = removing(suffix: suffix)
    }

    func removing(suffix: String) -> String {
        guard hasSuffix(suffix)
        else {
            return self
        }

        return String(dropLast(suffix.count))
    }

    func toHash() -> [String: String] {
        Dictionary(
            removing(prefix: "Build settings for action build and target Relish:")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: "\n")
                .map { $0.components(separatedBy: "=").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
                .compactMap { $0.count == 2 ? $0 : nil }
                .map { ($0[0], $0[1]) }
        ) { $1 }
    }
}
