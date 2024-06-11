import Foundation

extension Sequence where Element: Hashable {
    /// Returns the duplicate elements in the sequence.
    var duplicates: [Element] {
        let lookup: [Element: [Element]] = Dictionary(grouping: self, by: { $0 })

        return lookup.filter { $0.value.count > 1 }.map(\.key)
    }
}
