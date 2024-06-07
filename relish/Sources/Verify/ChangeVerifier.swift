import Foundation

/// A type that provides a change context for change verification.
protocol ChangeProviding {
    /// The context for a set of changes.
    func changeContext() async throws -> ChangeContext
}

extension ChangeProviding {
    /// The context for a set of changes.
    ///
    /// The method also logs the time taken to retrieve the change context.
    ///
    /// - Returns: The context from a set of changes.
    func measuredChangeContext() async throws -> ChangeContext {
        try await Duration.measure(String(describing: type(of: self))) {
            try await changeContext()
        }
    }
}

/// An object that verifies changes to the workspace.
struct ChangeVerifier {
    struct Failure: Error {
        var warnings: [ChangeVerificationFailure] {
            failures[.warning, default: []]
        }

        var fatalFailures: [ChangeVerificationFailure] {
            failures[.fatal, default: []]
        }

        private let failures: [ChangeVerificationFailure.Severity: [ChangeVerificationFailure]]

        init(failures: [ChangeVerificationFailure]) {
            self.failures = Dictionary(grouping: failures, by: \.severity)
        }
    }

    struct TimingMetrics: CustomDebugStringConvertible {
        var duration: Duration
        var tasks: [Task]

        struct Task {
            var duration: Duration
            var verification: any ChangeVerification
        }

        var debugDescription: String {
            """
            Verification total duration: \(duration.timingDescription)
            \(tasks.map { "  - \($0.verification.name): \($0.duration.timingDescription)" }
                .joined(separator: "\n"))
            """
        }
    }

    private struct VerificationResult {
        var failure: ChangeVerificationFailure?
        var task: TimingMetrics.Task
    }

    var isVerbose: Bool

    /// The provider for the change context.
    var changeProvider: ChangeProviding

    /// A collection of verifications to perform.
    var verifications: [any ChangeVerification]

    func verify() async throws -> Result<Void, ChangeVerifier.Failure> {
        let console = Console<NeverThrows>(isVerbose: isVerbose)
        let context = try await changeProvider.measuredChangeContext()

        let start = ContinuousClock.now
        let results: [VerificationResult] = await withTaskGroup(
            of: VerificationResult.self,
            body: { group in
                for verification in verifications {
                    group.addTask {
                        console.log(.info("Performing \(verification.name)."))
                        let result = await perform(verification, with: context)
                        console.log(.info("Finished performing \(verification.name)."))
                        return result
                    }
                }

                return await group.values().compactMap { $0 }
            }
        )

        let metrics = TimingMetrics(
            duration: ContinuousClock.now - start,
            tasks: results.sorted(by: { $0.task.verification.name < $1.task.verification.name }).map(\.task)
        )

        console.log(.step(metrics.debugDescription))

        let failures = results.compactMap(\.failure)

        if failures.isEmpty {
            return .success(())
        } else {
            return .failure(.init(failures: failures))
        }
    }

    private func perform(_ verification: any ChangeVerification,
                         with context: ChangeContext) async -> VerificationResult {
        let start = ContinuousClock.now
        let failure: ChangeVerificationFailure?

        do {
            try await verification.verify(context: context)
            failure = nil
        } catch let error as ChangeVerificationFailure {
            failure = error
        } catch {
            failure = .failed(for: verification, withError: error)
        }

        return VerificationResult(
            failure: failure,
            task: TimingMetrics.Task(duration: ContinuousClock.now - start, verification: verification)
        )
    }
}

extension ChangeVerificationFailure {
    static func failed(for verification: any ChangeVerification, withError error: Error) -> ChangeVerificationFailure {
        .init(
            issues: [
                .init(
                    description: .standardDescription(
                        "Failed to perform verification with the following error: \(error.localizedDescription)",
                        recoverySuggestion: "Please contact @relish for assistance."
                    )
                )
            ],
            severity: .fatal,
            verification: verification
        )
    }
}

extension TaskGroup {
    func values() async -> [ChildTaskResult] {
        var values: [ChildTaskResult] = []
        var iterator = makeAsyncIterator()

        while let next = await iterator.next() {
            values.append(next)
        }

        return values
    }
}

extension Duration {
    fileprivate var timingDescription: String {
        formatted(.units(allowed: [.seconds, .milliseconds]))
    }
}
