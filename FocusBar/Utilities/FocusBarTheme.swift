import SwiftUI

enum FocusBarTheme {
    static let focusAccent = Color.accentColor
    static let shortBreakAccent = Color.green
    static let longBreakAccent = Color.blue
    static let streakAccent = Color.orange

    static let cardCornerRadius: CGFloat = 10
    static let ringSize: CGFloat = 144
    static let ringLineWidth: CGFloat = 8

    static func accent(for sessionType: SessionType) -> Color {
        switch sessionType {
        case .pomodoro: return focusAccent
        case .shortBreak: return shortBreakAccent
        case .longBreak: return longBreakAccent
        }
    }
}

struct MenuBarActionRow: View {
    let title: String
    let systemImage: String
    let hint: String
    var isDestructive: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .frame(width: 16)
                    .foregroundStyle(isDestructive ? .red : .secondary)
                Text(title)
                    .foregroundStyle(isDestructive ? .red : .primary)
                Spacer()
            }
            .font(.callout)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }
}
