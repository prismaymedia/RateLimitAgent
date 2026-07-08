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
                .frame(width: 296)
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
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .medium))

            if case .countdown(let seconds) = store.state {
                Text(formattedTime(seconds))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.orange)
                    .monospacedDigit()
            }
        }
    }

    var iconName: String {
        switch store.state {
        case .checking:  return "antenna.radiowaves.left.and.right"
        case .available: return "checkmark.circle.fill"
        case .unknown:   return "questionmark.circle"
        case .countdown: return "timer"
        case .error:     return "exclamationmark.triangle.fill"
        }
    }

    func formattedTime(_ s: Int) -> String {
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}

// MARK: - Popover

struct ContentView: View {
    @Environment(RateLimitStore.self) var store
    @Environment(\.colorScheme) var colorScheme

    let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──
            header
            Divider().overlay(.separator.opacity(0.3))

            // ── Body ──
            VStack(spacing: 12) {
                modelRow
                statusRow
                stateSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .onReceive(ticker) { _ in
                switch store.state {
                case .countdown:
                    store.decrementCountdown()
                default:
                    break
                }
            }

            Divider().overlay(.separator.opacity(0.3))

            // ── Footer ──
            footer
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        colors: [.pink, Color(red: 0.76, green: 0.19, blue: 0.32)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 24, height: 24)
                Text("OC")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("OpenCode Free Models")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Info Rows

    private var modelRow: some View {
        HStack {
            Text("Model")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(store.modelName)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }

    private var statusRow: some View {
        HStack {
            Text("Status")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            StatusBadge(state: store.state)
        }
    }

    // MARK: State Section

    @ViewBuilder
    private var stateSection: some View {
        switch store.state {
        case .countdown(let seconds):
            countdownSection(seconds: seconds)
            checkNowButton
        case .available:
            availableSection
        case .checking:
            checkingSection
        case .error(let message):
            errorSection(message: message)
        case .unknown:
            checkNowButton
        }
    }

    private func countdownSection(seconds: Int) -> some View {
        VStack(spacing: 10) {
            VStack(spacing: 0) {
                HStack {
                    Text("Resets in")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formattedCountdown(seconds))
                        .font(.system(size: 21, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                ProgressView(value: progress)
                    .tint(LinearGradient(
                        colors: [Color(red: 0.91, green: 0.27, blue: 0.38), Color(red: 1.0, green: 0.42, blue: 0.51)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .scaleEffect(x: 1, y: 1.2, anchor: .center)
                    .padding(.top, 8)

                Text(resetTimeText)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 5)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.orange.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    private var checkNowButton: some View {
        Button {
            Task { await store.checkNow() }
        } label: {
            Text("⟳ Check Now")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.18), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var availableSection: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.green)
            Text("Free model is available")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.green)
            Text("No rate limit detected")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var checkingSection: some View {
        HStack {
            Spacer()
            ProgressView()
                .controlSize(.small)
            Spacer()
        }
        .padding(.vertical, 12)
    }

    private func errorSection(message: String) -> some View {
        VStack(spacing: 8) {
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)

            Button("Retry") { Task { await store.checkNow() } }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.vertical, 8)
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Text("Last check: \(store.lastCheckText)")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 9))
            .foregroundStyle(.tertiary)
            .onHover { inside in
                if inside { NSCursor.pointingHand.push() }
                else { NSCursor.pop() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: Helpers

    private var progress: Double {
        let total = store.lastRetryAfter
        guard total > 0 else { return 0 }
        return Double(store.currentCountdown) / Double(total)
    }

    private var resetTimeText: String {
        let reset = Date().addingTimeInterval(TimeInterval(store.currentCountdown))
        let f = DateFormatter(); f.timeStyle = .short
        return "Rate limit resets at \(f.string(from: reset))"
    }

    private func formattedCountdown(_ s: Int) -> String {
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let state: RateLimitState

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
                .overlay(Capsule().stroke(color.opacity(0.15), lineWidth: 1))
        )
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
