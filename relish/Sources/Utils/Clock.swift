import Foundation

/// A `Clock` defines the 'current' time.
///
/// This protocol exists to support substituting a fake clock instance inside of unit tests.
///
/// Outside of unit test code, you should always interact with the `Clock` protocol via the extensions to the `Date`
/// type, and the global `clock` instance.
///
/// For example, replace code like this:
/// ```swift
/// let date = Date()
/// let timeInterval = date.timeIntervalSinceNow
/// ```
/// With code like this:
/// ```swift
/// let date = Date(using: clock)
/// let timeInterval = date.timeIntervalSinceNow(using: clock)
/// ```
/// (Always use the global `clock` instance.)
///
/// In debug builds, the global `clock` instance can be temporarily replaced with a fake implementation (see
/// `MockClock`) by calling `Clock.TestHooks.using(customClock:)`.
///
/// In release builds, the global `clock` cannot be altered, and always uses the OS clock.
protocol Clock {
    /// Gets a date representing the current moment.
    var now: Date { get }

    /// Submits the block to the main queue to be run after the deadline, according to this clock.
    func at(_ date: Date, execute work: @escaping () -> Void)
}

extension Clock {
    /// Submits the block to the main queue to be run after the elapsed delay, according to this clock.
    func `in`(_ delay: TimeInterval, execute work: @escaping () -> Void) {
        at(Date(timeIntervalSinceNow: delay, using: self), execute: work)
    }
}

let clock: Clock = SystemClock()

struct SystemClock: Clock {
    var now: Date {
        Date()
    }

    func at(_ date: Date, execute work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + date.timeIntervalSinceNow(using: self), execute: work)
    }
}

extension Duration {
    private static let console: Console<NeverThrows> = Logger.verboseConsole

    public static func measure<Output>(
        _ name: String? = nil,
        _ file: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: UInt = #line,
        _ work: () throws -> Output
    ) rethrows -> Output {
        let start = ContinuousClock.now
        let output = try work()
        let prefix = name ?? description(file, function, line)
        let time = (ContinuousClock.now - start).formatted(.units(allowed: [.seconds, .milliseconds]))
        console.log(.info("\(prefix): \(time)"))
        return output
    }

    public static func measure<Output>(
        _ name: String? = nil,
        _ file: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: UInt = #line,
        _ work: () async throws -> Output
    ) async rethrows -> Output {
        let start = ContinuousClock.now
        let output = try await work()
        let prefix = name ?? description(file, function, line)
        let time = (ContinuousClock.now - start).formatted(.units(allowed: [.seconds, .milliseconds]))
        console.log(.info("\(prefix): \(time)"))
        return output
    }

    private static func description(
        _ file: StaticString = #file,
        _ function: StaticString = #function,
        _ line: UInt = #line
    ) -> String {
        let suffix = ".\(function):#\(line)"
        let filePath = file.description
        guard let url = URL(string: filePath) else {
            return filePath + suffix
        }
        return url.deletingPathExtension().lastPathComponent + suffix
    }
}
