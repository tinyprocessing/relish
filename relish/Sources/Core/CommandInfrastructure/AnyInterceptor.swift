import Foundation

class AnyInterceptor<T>: CommandInterceptor<Any> {
    override var type: InterceptorType { underlyingInterceptor.type }

    private let underlyingInterceptor: CommandInterceptor<T>

    init(_ underlyingInterceptor: CommandInterceptor<T>) {
        self.underlyingInterceptor = underlyingInterceptor
    }

    override func run(for command: RelishCommand) async throws -> Any {
        return try await underlyingInterceptor.run(for: command)
    }

    override func shouldIntercept(command: RelishCommand) async throws -> Bool {
        return try await underlyingInterceptor.shouldIntercept(command: command)
    }
}

extension CommandInterceptor {
    func eraseToAnyInterceptor() -> CommandInterceptor<Any> {
        return AnyInterceptor(self)
    }
}
