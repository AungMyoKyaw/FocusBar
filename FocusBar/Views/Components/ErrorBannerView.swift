import SwiftUI

struct ErrorBannerView: View {
    let error: AppError
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(error.localizedDescription)
                .font(.caption)
                .lineLimit(2)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .transition(.move(edge: .top).combined(with: .opacity))
        .task(id: error.localizedDescription) {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled {
                onDismiss()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.localizedDescription)")
        .accessibilityHint("Press to dismiss")
    }
}
