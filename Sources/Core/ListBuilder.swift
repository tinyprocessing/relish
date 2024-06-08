import Foundation

@resultBuilder public enum ListBuilder<I> {
    public typealias Aggregate = [I]

    @inlinable public static func buildBlock(_ components: Aggregate...) -> Aggregate {
        buildArray(components)
    }

    @inlinable public static func buildOptional(_ component: Aggregate?) -> Aggregate {
        component ?? []
    }

    @inlinable public static func buildEither(first component: Aggregate) -> Aggregate {
        component
    }

    @inlinable public static func buildEither(second component: Aggregate) -> Aggregate {
        component
    }

    @inlinable public static func buildArray(_ components: [Aggregate]) -> Aggregate {
        components.flatMap { $0 }
    }

    @inlinable public static func buildExpression(_ expression: I) -> Aggregate {
        [expression]
    }

    @inlinable public static func buildExpression(_ expression: I?) -> Aggregate {
        expression.map { [$0] } ?? []
    }

    @inlinable public static func buildExpression<S>(_ expression: S) -> Aggregate where S: Sequence, S.Element == I {
        Array(expression)
    }
}
