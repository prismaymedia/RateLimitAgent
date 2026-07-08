import Foundation
import Observation

// MARK: - State

enum RateLimitState: Equatable {
    case checking
    case available
    case countdown(seconds: Int)
    case error(message: String)
    case unknown
}

// MARK: - Observable Store

@MainActor
@Observable
final class RateLimitStore {
    var state: RateLimitState = .unknown
    var currentCountdown: Int = 0
    var lastRetryAfter: Int = 0
    var lastCheckText: String = "Never"
    let modelName: String

    private let checker: RateLimitChecker
    private var checkTask: Task<Void, Never>?
    private var autoRefreshTask: Task<Void, Never>?

    init(modelName: String = "deepseek-v4-flash-free") {
        self.modelName = modelName
        self.checker = RateLimitChecker()

        // Auto-refresh every 30 seconds
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard let self = self else { break }
                if case .unknown = self.state {
                    await self.checkNow()
                }
            }
        }

        // Initial check
        Task { [weak self] in
            await self?.checkNow()
        }
    }

    deinit {
        Task { @MainActor [weak self] in
            self?.checkTask?.cancel()
            self?.autoRefreshTask?.cancel()
        }
    }

    func checkNow() async {
        checkTask?.cancel()
        state = .checking

        checkTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                let retryAfter = try await self.checker.checkRateLimit(model: self.modelName)

                let now = Date()
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .short
                self.lastCheckText = formatter.localizedString(for: now, relativeTo: Date())

                if let retryAfter = retryAfter {
                    // Rate limited
                    self.lastRetryAfter = retryAfter
                    self.currentCountdown = retryAfter
                    self.state = .countdown(seconds: retryAfter)
                } else {
                    // Not rate limited
                    self.lastRetryAfter = 0
                    self.currentCountdown = 0
                    self.state = .available
                }
            } catch is CancellationError {
                return
            } catch {
                self.state = .error(message: error.localizedDescription)
            }
        }

        await checkTask?.value
    }

    func decrementCountdown() {
        if currentCountdown > 0 {
            currentCountdown -= 1
            state = .countdown(seconds: currentCountdown)

            if currentCountdown <= 0 {
                // Timer expired — re-check
                Task { await checkNow() }
            }
        }
    }
}
