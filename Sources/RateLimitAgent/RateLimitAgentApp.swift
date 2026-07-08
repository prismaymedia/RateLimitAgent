import SwiftUI
import AppKit

// MARK: - App Entry Point

@main
struct RateLimitAgentApp: App {
    @State private var store = RateLimitStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(store)
                .frame(width: 280)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu Bar Label

struct MenuBarLabel: View {
    let store: RateLimitStore

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .medium))
            if case .countdown(let seconds) = store.state {
                Text(formattedTime(seconds))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .monospacedDigit()
            }
        }
    }

    var iconName: String {
        switch store.state {
        case .checking:
            return "antenna.radiowaves.left.and.right"
        case .available, .unknown:
            return "checkmark.circle"
        case .countdown:
            return "timer"
        case .error:
            return "exclamationmark.triangle"
        }
    }

    func formattedTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Content View (Popover)

struct ContentView: View {
    @Environment(RateLimitStore.self) var store

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                Text("OpenCode Free Models")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Divider()

            // Model info
            VStack(alignment: .leading, spacing: 8) {
                LabeledContent("Model") {
                    Text(store.modelName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Status") {
                    StatusBadge(state: store.state)
                }

                switch store.state {
                case .countdown(let seconds):
                    CountdownView(seconds: seconds)
                        .padding(.top, 4)

                    Button("Check Now") {
                        Task { await store.checkNow() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)

                case .available:
                    Text("Free model is available for use")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                case .checking:
                    HStack {
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                        Spacer()
                    }
                    .padding(.top, 4)

                case .error(let message):
                    VStack(spacing: 8) {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.subheadline)

                        Button("Retry") {
                            Task { await store.checkNow() }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.top, 4)

                case .unknown:
                    Button("Check Rate Limit") {
                        Task { await store.checkNow() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal)

            Divider()

            // Footer
            HStack {
                Text("Last check: \(store.lastCheckText)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let state: RateLimitState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(color)
                .fontWeight(.medium)
        }
    }

    var label: String {
        switch state {
        case .checking:  return "Checking…"
        case .available: return "Available"
        case .countdown: return "Rate Limited"
        case .error:     return "Error"
        case .unknown:   return "Unknown"
        }
    }

    var color: Color {
        switch state {
        case .checking:  return .gray
        case .available: return .green
        case .countdown: return .orange
        case .error:     return .red
        case .unknown:   return .gray
        }
    }
}

// MARK: - Countdown View

struct CountdownView: View {
    let seconds: Int
    @Environment(RateLimitStore.self) var store
    @State private var now = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.orange)
                Text("Resets in")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formattedTime(seconds))
                    .font(.system(.title3, design: .monospaced, weight: .bold))
                    .foregroundStyle(.orange)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            ProgressView(value: progress)
                .tint(.orange)

            Text("Rate limit resets at \(resetTimeText)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .onReceive(timer) { _ in
            if seconds > 0 {
                store.decrementCountdown()
            }
        }
    }

    var progress: Double {
        let total = store.lastRetryAfter
        guard total > 0 else { return 0 }
        return Double(store.currentCountdown) / Double(total)
    }

    var resetTimeText: String {
        let reset = Date().addingTimeInterval(TimeInterval(seconds))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: reset)
    }

    func formattedTime(_ s: Int) -> String {
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%02d:%02d", m, sec)
    }
}
