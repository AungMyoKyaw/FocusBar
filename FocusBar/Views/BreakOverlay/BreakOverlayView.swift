import SwiftUI
import AppKit

@MainActor
final class BreakOverlayController {
    private var window: NSWindow?

    func show(viewModel: TimerViewModel) {
        dismiss()
        guard let screen = NSScreen.main else { return }

        let view = BreakOverlayView(
            timerViewModel: viewModel,
            onSkipBreak: { [weak self] in
                viewModel.skip()
                self?.dismiss()
            },
            onDismiss: { [weak self] in
                self?.dismiss()
            }
        )

        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hosting
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    func dismiss() {
        window?.close()
        window = nil
    }
}

struct BreakOverlayView: View {
    @State var timerViewModel: TimerViewModel
    let onSkipBreak: () -> Void
    let onDismiss: () -> Void

    private var accent: Color {
        FocusBarTheme.accent(for: timerViewModel.currentSessionType)
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.45).ignoresSafeArea())

            VStack(spacing: 22) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(accent)
                        .frame(width: 8, height: 8)
                    Text(timerViewModel.currentSessionType.displayName.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(1.6)
                        .foregroundStyle(accent)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(accent.opacity(0.16), in: Capsule())

                Text(timerViewModel.formattedTime)
                    .font(.system(size: 72, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text("Step away from the screen, stretch, and rest your eyes.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)

                HStack(spacing: 12) {
                    Button("Dismiss (Esc)") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut(.escape, modifiers: [])

                    Button("Skip Break") {
                        onSkipBreak()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .controlSize(.large)
                }
                .padding(.top, 6)
            }
            .padding(44)
            .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
        }
        .onChange(of: timerViewModel.timerState) { _, newState in
            if newState == .idle {
                onDismiss()
            }
        }
    }
}
