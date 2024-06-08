import Foundation

extension Collection {
    @inlinable public var isNotEmpty: Bool {
        !isEmpty
    }

    @inlinable public var nilIfEmpty: Self? {
        isEmpty ? nil : self
    }

    public func compacted<Wrapped>() -> [Wrapped] where Element == Wrapped? {
        compactMap { $0 }
    }
}

extension Collection where Element: Collection {
    public func flattened() -> [Element.Element] {
        flatMap { $0 }
    }
}
