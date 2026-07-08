import SwiftUI
import AppKit

// MARK: - App Entry Point

@main
struct RateLimitAgentApp: App {
    @State private var store = RateLimitStore()

    var body: some Scene {
        WindowGroup {
            Color.clear.frame(width: 0, height: 0).hidden()
                .onAppear {
                    DispatchQueue.main.async {
                        if let w = NSApplication.shared.windows.first {
                            w.close()
                        }
                        MenuBarController.shared.start(with: store)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0, height: 0)
    }
}

// MARK: - Menu Bar Controller

@MainActor
final class MenuBarController: NSObject {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private weak var store: RateLimitStore?
    private var observationTask: Task<Void, Never>?

    private override init() {}

    func start(with store: RateLimitStore) {
        self.store = store

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = item

        guard let button = item.button else { return }
        button.action = #selector(togglePopover)
        button.target = self

        // Render initial image
        updateImage()

        // Watch for store changes
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                await MainActor.run { self?.updateImage() }
            }
        }

        // Create popover
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView().environment(store).frame(width: 296)
        )
        self.popover = popover
    }

    deinit {
        observationTask?.cancel()
    }

    private func updateImage() {
        guard let store = store else { return }

        let labelView = MenuBarLabel(store: store).environment(store)
        let renderer = ImageRenderer(content: labelView)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0

        guard let image = renderer.nsImage else { return }

        // Set as button image — using `isTemplate = false` preserves colors
        let statusImage = image
        statusImage.isTemplate = false
        statusItem?.button?.image = statusImage
        statusItem?.button?.imagePosition = .imageOnly
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover?.isShown == true {
            popover?.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover?.contentViewController?.view.window?.makeKey()
        }
    }
}

// MARK: - Menu Bar Label

struct MenuBarLabel: View {
    let store: RateLimitStore

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(foregroundColor)

            if case .countdown(let seconds) = store.state {
                Text(formattedTime(seconds))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(foregroundColor)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    private var iconName: String {
        switch store.state {
        case .checking:  return "antenna.radiowaves.left.and.right"
        case .available: return "checkmark.circle.fill"
        case .unknown:   return "questionmark.circle"
        case .countdown: return "timer"
        case .error:     return "exclamationmark.triangle.fill"
        }
    }

    private var foregroundColor: Color {
        switch store.state {
        case .countdown: return .orange
        case .available: return .green
        case .error:     return .orange
        case .checking, .unknown: return .primary
        }
    }

    func formattedTime(_ s: Int) -> String {
        let h = s / 3600; let m = (s % 3600) / 60; let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}

// MARK: - Popover Content

struct ContentView: View {
    @Environment(RateLimitStore.self) var store
    let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(.separator.opacity(0.3))
            VStack(spacing: 12) {
                modelRow
                statusRow
                stateSection
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .onReceive(ticker) { _ in
                if case .countdown = store.state { store.decrementCountdown() }
            }
            Divider().overlay(.separator.opacity(0.3))
            footer
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [.pink, Color(red: 0.76, green: 0.19, blue: 0.32)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 24, height: 24)
                Text("OC").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
            }
            Text("OpenCode Free Models").font(.system(size: 13, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private var modelRow: some View {
        HStack {
            Text("Model").font(.system(size: 11)).foregroundStyle(.secondary)
            Spacer()
            Text(store.modelName).font(.system(size: 11, weight: .medium, design: .monospaced))
        }
    }

    private var statusRow: some View {
        HStack {
            Text("Status").font(.system(size: 11)).foregroundStyle(.secondary)
            Spacer()
            StatusBadge(state: store.state)
        }
    }

    @ViewBuilder
    private var stateSection: some View {
        switch store.state {
        case .countdown(let seconds):
            countdownCard(seconds: seconds)
            checkNowButton
        case .available:
            availableCard
        case .checking:
            HStack { Spacer(); ProgressView().controlSize(.small); Spacer() }.padding(.vertical, 12)
        case .error(let message):
            errorCard(message: message)
        case .unknown:
            checkNowButton
        }
    }

    private func countdownCard(seconds: Int) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("Resets in").font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Text(formattedCD(seconds))
                    .font(.system(size: 21, weight: .bold, design: .monospaced))
                    .foregroundStyle(.orange).monospacedDigit().contentTransition(.numericText())
            }
            ProgressView(value: progress)
                .tint(LinearGradient(colors: [Color(red: 0.91, green: 0.27, blue: 0.38), Color(red: 1.0, green: 0.42, blue: 0.51)], startPoint: .leading, endPoint: .trailing))
                .scaleEffect(x: 1, y: 1.2, anchor: .center)
            Text(resetAtText).font(.system(size: 9)).foregroundStyle(.tertiary).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.1), lineWidth: 1)))
    }

    private var checkNowButton: some View {
        Button { Task { await store.checkNow() } } label: {
            Text("⟳ Check Now").font(.system(size: 12, weight: .semibold)).foregroundStyle(.orange)
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.08)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.18), lineWidth: 1)))
        }.buttonStyle(.plain)
    }

    private var availableCard: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 24)).foregroundStyle(.green)
            Text("Free model is available").font(.system(size: 12, weight: .medium)).foregroundStyle(.green)
            Text("No rate limit detected").font(.system(size: 10)).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.05)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.1), lineWidth: 1)))
    }

    private func errorCard(message: String) -> some View {
        VStack(spacing: 8) {
            Label(message, systemImage: "exclamationmark.triangle").font(.system(size: 11)).foregroundStyle(.orange).multilineTextAlignment(.center)
            Button("Retry") { Task { await store.checkNow() } }
                .buttonStyle(.plain).font(.system(size: 11, weight: .semibold)).foregroundStyle(.orange)
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).stroke(Color.orange.opacity(0.3), lineWidth: 1))
        }.padding(.vertical, 8)
    }

    private var footer: some View {
        HStack {
            Text("Last check: \(store.lastCheckText)").font(.system(size: 9)).foregroundStyle(.tertiary)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }.buttonStyle(.plain).font(.system(size: 9)).foregroundStyle(.tertiary)
        }.padding(.horizontal, 16).padding(.vertical, 10)
    }

    private var progress: Double {
        guard store.lastRetryAfter > 0 else { return 0 }
        return Double(store.currentCountdown) / Double(store.lastRetryAfter)
    }

    private var resetAtText: String {
        let f = DateFormatter(); f.timeStyle = .short
        return "Rate limit resets at \(f.string(from: Date().addingTimeInterval(TimeInterval(store.currentCountdown))))"
    }

    private func formattedCD(_ s: Int) -> String {
        let h = s / 3600; let m = (s % 3600) / 60; let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let state: RateLimitState

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundStyle(color)
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.1)).overlay(Capsule().stroke(color.opacity(0.15), lineWidth: 1)))
    }

    private var label: String {
        switch state {
        case .checking:  return "Checking…"
        case .available: return "Available"
        case .countdown: return "Rate Limited"
        case .error:     return "Error"
        case .unknown:   return "Unknown"
        }
    }

    private var color: Color {
        switch state {
        case .checking:  return .gray
        case .available: return .green
        case .countdown: return .orange
        case .error:     return .red
        case .unknown:   return .gray
        }
    }
}
