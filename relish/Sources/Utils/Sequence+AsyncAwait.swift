import Foundation

extension Sequence {
    public func concurrentAsyncMap<T>(
        _ transform: @escaping (Element) async throws -> T
    ) async throws -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }

        return try await tasks.asyncMap { task in
            try await task.value
        }
    }

    public func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }

    /// Returns an array containing, in order, the elements of the sequence
    /// that satisfy the given async predicate.
    ///
    /// - Parameter isIncluded: An async closure that takes an element of the
    ///   sequence as its argument and returns a Boolean value indicating
    ///   whether the element should be included in the returned array.
    /// - Returns: An array of the elements that `isIncluded` allowed.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    public func asyncFilter(_ isIncluded: (Self.Element) async throws -> Bool) async rethrows -> [Self.Element] {
        var included = [Element]()

        for element in self {
            if try await isIncluded(element) {
                included.append(element)
            }
        }

        return included
    }

    public func concurrentAsyncCompactMap<T>(
        _ transform: @escaping (Element) async throws -> T?
    ) async throws -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }

        return try await tasks.asyncCompactMap { task in
            try await task.value
        }
    }

    public func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            guard let transformedElement = try await transform(element) else { continue }

            values.append(transformedElement)
        }

        return values
    }

    public func serialAsyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
