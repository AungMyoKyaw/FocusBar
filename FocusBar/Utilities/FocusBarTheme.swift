import SwiftUI

enum FocusBarTheme {
    static let focusAccent = Color.accentColor
    static let shortBreakAccent = Color.green
    static let longBreakAccent = Color.blue
    static let streakAccent = Color.orange

    static let cardCornerRadius: CGFloat = 12
    static let controlCornerRadius: CGFloat = 10
    static let ringSize: CGFloat = 164
    static let ringLineWidth: CGFloat = 7

    static func accent(for sessionType: SessionType) -> Color {
        switch sessionType {
        case .pomodoro: return focusAccent
        case .shortBreak: return shortBreakAccent
        case .longBreak: return longBreakAccent
        }
    }
}

extension View {
    @ViewBuilder
    func focusGlassCapsule(tint: Color? = nil, interactive: Bool = true) -> some View {
        if #available(macOS 26, *) {
            if let tint {
                self.glassEffect(.regular.tint(tint).interactive(interactive), in: Capsule())
            } else {
                self.glassEffect(.regular.interactive(interactive), in: Capsule())
            }
        } else {
            self.background(
                (tint ?? Color.primary).opacity(tint == nil ? 0.08 : 0.16),
                in: Capsule()
            )
        }
    }

    func focusCardSurface(cornerRadius: CGFloat = FocusBarTheme.cardCornerRadius) -> some View {
        self
            .background(
                .quaternary.opacity(0.45),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

struct MenuBarDockButton: View {
    let title: String
    let systemImage: String
    let hint: String
    var isDestructive: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .medium))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isDestructive && isHovered ? .red : (isHovered ? .primary : .secondary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        isDestructive && isHovered
                            ? Color.red.opacity(0.12)
                            : (isHovered ? Color.primary.opacity(0.08) : Color.clear)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }
}
