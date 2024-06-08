import Foundation

extension NSRegularExpression {
    public struct FormattedMatch {
        /// The overall match.
        public var match: String

        /// The capture groups in the `match` (if any).
        public var captureGroups: [String]

        public init(match: String, captureGroups: [String]) {
            self.match = match
            self.captureGroups = captureGroups
        }
    }

    public func formattedMatches(
        in string: String,
        options: NSRegularExpression.MatchingOptions = [],
        range: Range<String.Index>
    ) -> [FormattedMatch] {
        let matches = matches(in: string, options: options, range: NSRange(range, in: string)).compactMap {
            FormattedMatch(result: $0, string: string)
        }

        return matches
    }

    public func firstFormattedMatch(
        in string: String,
        options: NSRegularExpression.MatchingOptions = [],
        range: Range<String.Index>
    ) -> FormattedMatch? {
        formattedMatches(in: string, range: range).first
    }
}

extension NSRegularExpression.FormattedMatch {
    fileprivate init?(result: NSTextCheckingResult, string: String) {
        guard let fullRange = Range(result.range(at: 0), in: string) else {
            return nil
        }

        match = String(string[fullRange])

        if result.numberOfRanges > 1 {
            captureGroups = (1..<result.numberOfRanges).compactMap { rangeIndex in
                guard let matchRange = Range(result.range(at: rangeIndex), in: string) else {
                    return nil
                }

                return String(string[matchRange])
            }
        } else {
            captureGroups = []
        }
    }
}
