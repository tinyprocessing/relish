import Foundation

extension Date {
    /// Creates a date value initialized to the current date and time, according to the clock.
    init(using clock: Clock) {
        self = clock.now
    }

    /// Creates a date value initialized relative to the current date and time by a given number of seconds, according
    /// to the clock.
    init(timeIntervalSinceNow: TimeInterval, using clock: Clock) {
        self.init(timeInterval: timeIntervalSinceNow, since: clock.now)
    }

    /// The time interval between the date value and the current date and time, according to the clock.
    func timeIntervalSinceNow(using clock: Clock) -> TimeInterval {
        return timeIntervalSince(clock.now)
    }

    /// Returns the number of milliseconds between 1970 and this Date.
    ///
    var millisecondsSince1970: Int64 {
        Int64(round(timeIntervalSince1970 * 1000))
    }

    /// Returns the number of milliseconds between the given Date and this Date.
    ///
    func millisecondsSince(_ date: Date) -> Int64 {
        Int64(round(timeIntervalSince(date) * 1000))
    }

    /// Returns the number of seconds between the given Date and this Date.
    ///
    func secondsSince(_ date: Date) -> Int64 {
        Int64(round(timeIntervalSince(date)))
    }
}
