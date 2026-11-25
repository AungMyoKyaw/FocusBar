import SwiftUI
import AppKit

private final class DraggableFloatingPanel: NSPanel {
    var isDragLocked: Bool = false
    var onDragEnded: ((NSPoint) -> Void)?

    private var dragStartMouse: NSPoint?
    private var dragStartOrigin: NSPoint?
    private var didDrag = false

    override var canBecomeKey: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown where !isDragLocked:
            dragStartMouse = NSEvent.mouseLocation
            dragStartOrigin = frame.origin
            didDrag = false
            super.sendEvent(event)

        case .leftMouseDragged where !isDragLocked:
            if let startMouse = dragStartMouse, let startOrigin = dragStartOrigin {
                let current = NSEvent.mouseLocation
                let dx = current.x - startMouse.x
                let dy = current.y - startMouse.y
                if didDrag || hypot(dx, dy) > 4 {
                    didDrag = true
                    setFrameOrigin(NSPoint(x: startOrigin.x + dx, y: startOrigin.y + dy))
                    return
                }
            }
            super.sendEvent(event)

        case .leftMouseUp:
            let wasDrag = didDrag
            dragStartMouse = nil
            dragStartOrigin = nil
            didDrag = false
            if wasDrag {
                onDragEnded?(frame.origin)
                return
            }
            super.sendEvent(event)

        default:
            super.sendEvent(event)
        }
    }
}

@MainActor
final class FloatingTimerPanelController {
    private var panel: DraggableFloatingPanel?
    private var hostingController: NSHostingController<FloatingTimerView>?
    private var moveObserver: NSObjectProtocol?
    private weak var currentViewModel: TimerViewModel?
    private let defaults: UserDefaults

    var size: FloatingWidgetSize
    var isLocked: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let rawSize = defaults.string(forKey: UserDefaultsKeys.floatingWidgetSize) ?? FloatingWidgetSize.compact.rawValue
        self.size = FloatingWidgetSize(rawValue: rawSize) ?? .compact
        self.isLocked = defaults.bool(forKey: UserDefaultsKeys.floatingWidgetLocked)
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func toggle(viewModel: TimerViewModel) {
        if isVisible {
            hide()
        } else {
            show(viewModel: viewModel)
        }
    }

    func show(viewModel: TimerViewModel) {
        currentViewModel = viewModel
        if let panel {
            panel.orderFrontRegardless()
            return
        }

        let dims = size.dimensions
        let contentView = makeRootView(viewModel: viewModel)
        let hosting = NSHostingController(rootView: contentView)
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = NSColor.clear.cgColor
        self.hostingController = hosting

        let panel = DraggableFloatingPanel(
            contentRect: NSRect(origin: .zero, size: dims),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hosting
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isDragLocked = isLocked
        panel.isMovable = !isLocked
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.onDragEnded = { [weak self] origin in
            self?.defaults.set(Double(origin.x), forKey: UserDefaultsKeys.floatingWidgetOriginX)
            self?.defaults.set(Double(origin.y), forKey: UserDefaultsKeys.floatingWidgetOriginY)
        }

        let origin = restoredOrigin(for: dims)
        panel.setFrame(NSRect(origin: origin, size: dims), display: true)

        moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            guard let self, let frame = self.panel?.frame else { return }
            self.defaults.set(Double(frame.origin.x), forKey: UserDefaultsKeys.floatingWidgetOriginX)
            self.defaults.set(Double(frame.origin.y), forKey: UserDefaultsKeys.floatingWidgetOriginY)
        }

        panel.orderFrontRegardless()
        self.panel = panel
    }

    func setSize(_ newSize: FloatingWidgetSize) {
        size = newSize
        defaults.set(newSize.rawValue, forKey: UserDefaultsKeys.floatingWidgetSize)

        guard let panel else { return }
        let newDims = newSize.dimensions
        let oldFrame = panel.frame
        let center = NSPoint(x: oldFrame.midX, y: oldFrame.midY)
        var newOrigin = NSPoint(x: center.x - newDims.width / 2, y: center.y - newDims.height / 2)

        if let screenFrame = (panel.screen ?? NSScreen.main)?.visibleFrame {
            newOrigin.x = min(max(newOrigin.x, screenFrame.minX), screenFrame.maxX - newDims.width)
            newOrigin.y = min(max(newOrigin.y, screenFrame.minY), screenFrame.maxY - newDims.height)
        }

        if let vm = currentViewModel {
            hostingController?.rootView = makeRootView(viewModel: vm)
        }
        panel.setFrame(NSRect(origin: newOrigin, size: newDims), display: true, animate: true)
    }

    func cycleSize() {
        let all = FloatingWidgetSize.allCases
        if let idx = all.firstIndex(of: size) {
            setSize(all[(idx + 1) % all.count])
        }
    }

    func setLocked(_ locked: Bool) {
        isLocked = locked
        defaults.set(locked, forKey: UserDefaultsKeys.floatingWidgetLocked)
        panel?.isDragLocked = locked
        panel?.isMovable = !locked
        if let vm = currentViewModel {
            hostingController?.rootView = makeRootView(viewModel: vm)
        }
    }

    func hide() {
        if let moveObserver {
            NotificationCenter.default.removeObserver(moveObserver)
        }
        moveObserver = nil
        panel?.close()
        panel = nil
        hostingController = nil
    }

    private func makeRootView(viewModel: TimerViewModel) -> FloatingTimerView {
        FloatingTimerView(
            timerViewModel: viewModel,
            widgetSize: size,
            isLocked: isLocked,
            onSelectSize: { [weak self] newSize in self?.setSize(newSize) },
            onCycleSize: { [weak self] in self?.cycleSize() },
            onToggleLock: { [weak self] in
                guard let self else { return }
                self.setLocked(!self.isLocked)
            },
            onClose: { [weak self] in
                self?.hide()
                viewModel.isFloatingTimerVisible = false
            }
        )
    }

    private func restoredOrigin(for dims: CGSize) -> NSPoint {
        if defaults.object(forKey: UserDefaultsKeys.floatingWidgetOriginX) != nil,
           defaults.object(forKey: UserDefaultsKeys.floatingWidgetOriginY) != nil {
            let x = defaults.double(forKey: UserDefaultsKeys.floatingWidgetOriginX)
            let y = defaults.double(forKey: UserDefaultsKeys.floatingWidgetOriginY)
            let candidate = NSRect(origin: NSPoint(x: x, y: y), size: dims)
            if NSScreen.screens.contains(where: { $0.visibleFrame.intersects(candidate) }) {
                return candidate.origin
            }
        }
        if let visible = NSScreen.main?.visibleFrame {
            return NSPoint(x: visible.maxX - dims.width - 20, y: visible.maxY - dims.height - 20)
        }
        return NSPoint(x: 100, y: 100)
    }

    deinit {
        if let moveObserver {
            NotificationCenter.default.removeObserver(moveObserver)
        }
    }
}

struct FloatingTimerView: View {
    @State var timerViewModel: TimerViewModel
    let widgetSize: FloatingWidgetSize
    let isLocked: Bool
    let onSelectSize: (FloatingWidgetSize) -> Void
    let onCycleSize: () -> Void
    let onToggleLock: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false

    private var accent: Color {
        FocusBarTheme.accent(for: timerViewModel.currentSessionType)
    }

    var body: some View {
        Group {
            switch widgetSize {
            case .micro:
                microRingView
            case .compact:
                compactPillView
            case .expanded:
                expandedDialView
            }
        }
        .onHover { isHovered = $0 }
        .contextMenu {
            Menu("Widget Size") {
                ForEach(FloatingWidgetSize.allCases, id: \.self) { sizeOption in
                    Button {
                        onSelectSize(sizeOption)
                    } label: {
                        if sizeOption == widgetSize {
                            Label(sizeOption.displayName, systemImage: "checkmark")
                        } else {
                            Text(sizeOption.displayName)
                        }
                    }
                }
            }

            Button(isLocked ? "Unlock Position" : "Lock Position") {
                onToggleLock()
            }

            Divider()

            if timerViewModel.isOvertime {
                Button("Finish & Log") { timerViewModel.completeOvertimeSession() }
            } else if timerViewModel.timerState == .idle {
                Button("Start Focus") { timerViewModel.startFocus() }
            } else {
                Button(timerViewModel.timerState == .running ? "Pause" : "Resume") {
                    timerViewModel.togglePauseResume()
                }
                Button("Extend +5m") { timerViewModel.extendActiveSession(by: 5) }
                Button("Skip Session") { timerViewModel.skip() }
                Button("Reset") { timerViewModel.reset() }
            }

            Divider()

            Button("Hide Floating Widget", action: onClose)
        }
    }

    // MARK: - Micro (Ring Only: 56x56)

    private var microRingView: some View {
        let isIdle = timerViewModel.timerState == .idle
        let progress = isIdle ? 0 : timerViewModel.sessionProgress
        let mins = max(0, (timerViewModel.isOvertime ? timerViewModel.overtimeSeconds : timerViewModel.remainingSeconds) / 60)

        return Button {
            handlePrimaryAction()
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)

                ForEach(0..<12, id: \.self) { tick in
                    Rectangle()
                        .fill(Color.primary.opacity(0.18))
                        .frame(width: 1, height: 3)
                        .offset(y: -21)
                        .rotationEffect(.degrees(Double(tick) * 30))
                }

                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 4.5)
                    .padding(4)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accent, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(4)

                if isHovered || isIdle {
                    Image(systemName: playPauseIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accent)
                } else {
                    Text(timerViewModel.isOvertime ? "+\(mins)" : "\(mins)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: 56, height: 56)
            .overlay(
                Circle()
                    .strokeBorder(Color.primary.opacity(0.16), lineWidth: 1)
            )
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help("Click to Start/Pause · Drag anywhere · Right-click for size")
    }

    // MARK: - Compact (Pill: 224x54)

    private var compactPillView: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.14), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: timerViewModel.timerState == .idle ? 0 : timerViewModel.sessionProgress)
                    .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .fill(accent)
                    .frame(width: 6, height: 6)
                    .opacity(timerViewModel.timerState == .paused ? 0.4 : 1)
            }
            .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text(timerViewModel.timerState == .idle ? timerViewModel.configuredDurationFormatted : timerViewModel.formattedTime)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text(timerViewModel.isOvertime ? "OVERTIME" : timerViewModel.currentSessionType.displayName.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(accent)
            }

            Spacer(minLength: 2)

            Button(action: onCycleSize) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Cycle widget size")

            Button(action: handlePrimaryAction) {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(accent, in: Circle())
            }
            .buttonStyle(.plain)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Hide floating timer")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 224, height: 54)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
        )
    }

    // MARK: - Expanded (Mini Chronograph Card: 176x204)

    private var expandedDialView: some View {
        let isIdle = timerViewModel.timerState == .idle
        let progress = isIdle ? 0 : timerViewModel.sessionProgress
        let timeText = isIdle ? timerViewModel.configuredDurationFormatted : timerViewModel.formattedTime

        return VStack(spacing: 10) {
            HStack {
                Text(timerViewModel.isOvertime ? "OVERTIME" : timerViewModel.currentSessionType.displayName.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(accent)

                Spacer()

                Button(action: onCycleSize) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Cycle widget size")

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Hide floating timer")
            }

            ZStack {
                ForEach(0..<30, id: \.self) { tick in
                    let isMajor = tick % 5 == 0
                    Rectangle()
                        .fill(Color.primary.opacity(isMajor ? 0.24 : 0.10))
                        .frame(width: isMajor ? 1.5 : 1, height: isMajor ? 5 : 3)
                        .offset(y: -48)
                        .rotationEffect(.degrees(Double(tick) * 12))
                }

                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text(timeText)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            .frame(width: 112, height: 112)

            HStack(spacing: 12) {
                Button {
                    timerViewModel.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.primary.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isIdle)

                Button(action: handlePrimaryAction) {
                    Image(systemName: playPauseIcon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 28)
                        .background(accent, in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    timerViewModel.skip()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.primary.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 176, height: 204)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
        )
    }

    private func handlePrimaryAction() {
        if timerViewModel.isOvertime {
            timerViewModel.completeOvertimeSession()
        } else if timerViewModel.timerState == .idle {
            timerViewModel.startFocus()
        } else {
            timerViewModel.togglePauseResume()
        }
    }

    private var playPauseIcon: String {
        if timerViewModel.isOvertime { return "checkmark" }
        return timerViewModel.timerState == .running ? "pause.fill" : "play.fill"
    }
}
