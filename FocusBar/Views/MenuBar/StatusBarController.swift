import AppKit
import Observation
import SwiftData
import SwiftUI

enum StatusBarLayoutMetrics {
    static let iconLength: CGFloat = 28
    static let progressBarLength: CGFloat = 66
    static let standardTimerLength: CGFloat = 68
    static let extendedTimerLength: CGFloat = 74
    static let standardEndTimeLength: CGFloat = 114
    static let extendedEndTimeLength: CGFloat = 122

    static func length(
        displayMode: MenuBarDisplayMode,
        isIdle: Bool,
        isOvertime: Bool,
        remainingSeconds: Int,
        showEndTime: Bool
    ) -> CGFloat {
        if isIdle || displayMode == .icon {
            return iconLength
        }
        switch displayMode {
        case .icon:
            return iconLength
        case .progressBar:
            return progressBarLength
        case .timerText:
            let needsExtraDigitWidth = isOvertime || remainingSeconds >= 6000
            if showEndTime {
                return needsExtraDigitWidth ? extendedEndTimeLength : standardEndTimeLength
            }
            return needsExtraDigitWidth ? extendedTimerLength : standardTimerLength
        }
    }
}

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let timerViewModel: TimerViewModel
    private let defaults: UserDefaults

    private let monospacedFont = NSFont.monospacedDigitSystemFont(
        ofSize: NSFont.systemFontSize(for: .regular),
        weight: .regular
    )
    private let symbolConfig = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)

    private var hasRenderedOnce = false
    private var lastLength: CGFloat = -1
    private var lastTitle: String?
    private var lastImageKey: String?
    private var lastModeKey: String?
    private var observationGeneration: Int = 0

    private weak var observedWindow: NSWindow?
    nonisolated(unsafe) private var occlusionObserver: NSObjectProtocol?
    nonisolated(unsafe) private var defaultsObserver: NSObjectProtocol?

    init(
        timerViewModel: TimerViewModel,
        modelContainer: ModelContainer,
        defaults: UserDefaults = .standard,
        onOpenWindow: @escaping (String) -> Void
    ) {
        self.timerViewModel = timerViewModel
        self.defaults = defaults
        self.statusItem = NSStatusBar.system.statusItem(withLength: StatusBarLayoutMetrics.iconLength)

        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        let rootView = MenuBarView(timerViewModel: timerViewModel, onOpenWindow: onOpenWindow)
            .modelContainer(modelContainer)
        popover.contentViewController = NSHostingController(rootView: rootView)
        self.popover = popover

        super.init()

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.imagePosition = .imageOnly
        }

        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleDefaultsChange()
            }
        }

        render(force: true)
        startObservationTracking()
    }

    deinit {
        if let occlusionObserver {
            NotificationCenter.default.removeObserver(occlusionObserver)
        }
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    func closePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func currentDisplayMode() -> MenuBarDisplayMode {
        let raw = defaults.string(forKey: UserDefaultsKeys.menuBarDisplayMode) ?? MenuBarDisplayMode.timerText.rawValue
        return MenuBarDisplayMode(rawValue: raw) ?? .timerText
    }

    private func startObservationTracking() {
        observationGeneration += 1
        let generation = observationGeneration
        let mode = currentDisplayMode()

        withObservationTracking {
            _ = timerViewModel.timerState
            _ = timerViewModel.currentSessionType
            _ = timerViewModel.isOvertime
            switch mode {
            case .icon:
                break
            case .progressBar:
                _ = timerViewModel.sessionProgress
            case .timerText:
                _ = timerViewModel.remainingSeconds
                _ = timerViewModel.overtimeSeconds
            }
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.observationGeneration == generation else { return }
                self.render(force: false)
                self.startObservationTracking()
            }
        }
    }

    private func handleDefaultsChange() {
        render(force: true)
        startObservationTracking()
    }

    private func attachOcclusionObserverIfNeeded(for button: NSStatusBarButton) {
        guard let window = button.window, window !== observedWindow else { return }
        if let occlusionObserver {
            NotificationCenter.default.removeObserver(occlusionObserver)
            self.occlusionObserver = nil
        }
        observedWindow = window
        occlusionObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let currentWindow = self.statusItem.button?.window else { return }
                if currentWindow.occlusionState.contains(.visible) {
                    self.render(force: true)
                }
            }
        }
    }

    private func render(force: Bool) {
        guard let button = statusItem.button else { return }
        attachOcclusionObserverIfNeeded(for: button)

        let displayMode = currentDisplayMode()
        let showEndTime = defaults.bool(forKey: UserDefaultsKeys.showEndTimeInMenuBar)
        let isIdle = timerViewModel.timerState == .idle
        let targetLength = StatusBarLayoutMetrics.length(
            displayMode: displayMode,
            isIdle: isIdle,
            isOvertime: timerViewModel.isOvertime,
            remainingSeconds: timerViewModel.remainingSeconds,
            showEndTime: showEndTime
        )
        let modeKey = "\(displayMode.rawValue)|\(showEndTime)|\(isIdle)"

        // When the status item is occluded (e.g. crowded menu bar / behind notch), skip
        // 1Hz tick mutations completely so macOS never oscillates menu bar layout.
        if !force,
           hasRenderedOnce,
           modeKey == lastModeKey,
           targetLength == lastLength,
           let window = button.window,
           (!window.isVisible || !window.occlusionState.contains(.visible)) {
            return
        }

        if statusItem.length != targetLength {
            statusItem.length = targetLength
        }
        lastLength = targetLength
        lastModeKey = modeKey

        let symbolName = timerViewModel.menuBarSystemImage
        let newTitle: String
        let imageKey: String

        if isIdle || displayMode == .icon {
            newTitle = ""
            imageKey = "symbol:\(symbolName)"
        } else if displayMode == .progressBar {
            let bucket = Int((timerViewModel.sessionProgress * 34.0).rounded())
            newTitle = ""
            imageKey = "progress:\(symbolName):\(bucket)"
        } else {
            newTitle = timerViewModel.menuBarTitle
            imageKey = "symbol:\(symbolName)"
        }

        if imageKey != lastImageKey {
            if displayMode == .progressBar, !isIdle {
                let bucket = Int((timerViewModel.sessionProgress * 34.0).rounded())
                button.image = renderProgressImage(symbolName: symbolName, filledPixels: bucket)
            } else {
                let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
                    .withSymbolConfiguration(symbolConfig)
                image?.isTemplate = true
                button.image = image
            }
            lastImageKey = imageKey
        }

        if newTitle != lastTitle {
            if newTitle.isEmpty {
                button.attributedTitle = NSAttributedString(string: "")
                button.imagePosition = .imageOnly
            } else {
                button.attributedTitle = NSAttributedString(
                    string: newTitle,
                    attributes: [.font: monospacedFont]
                )
                button.imagePosition = .imageLeading
            }
            lastTitle = newTitle
        }

        hasRenderedOnce = true
    }

    private func renderProgressImage(symbolName: String, filledPixels: Int) -> NSImage {
        let size = NSSize(width: 54, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            if let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
                .withSymbolConfiguration(self.symbolConfig) {
                let symbolSize = symbol.size
                let y = (size.height - symbolSize.height) / 2.0
                symbol.draw(in: NSRect(x: 0, y: y, width: symbolSize.width, height: symbolSize.height))
            }

            let trackRect = NSRect(x: 18, y: 6.5, width: 34, height: 5)
            let trackPath = NSBezierPath(roundedRect: trackRect, xRadius: 2.5, yRadius: 2.5)
            NSColor.labelColor.withAlphaComponent(0.28).setFill()
            trackPath.fill()

            let clampedWidth = max(4, min(34, CGFloat(filledPixels)))
            if filledPixels > 0 {
                let fillRect = NSRect(x: 18, y: 6.5, width: clampedWidth, height: 5)
                let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 2.5, yRadius: 2.5)
                NSColor.labelColor.setFill()
                fillPath.fill()
            }

            return true
        }
        image.isTemplate = true
        return image
    }
}
