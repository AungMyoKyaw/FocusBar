import SwiftUI

struct ErrorBannerView: View {
    let error: AppError
    let onDismiss: () -> Void

    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)

                Text(error.localizedDescription)
                    .font(.caption)
                    .lineLimit(2)

                Spacer()

                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    dismiss()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Error: \(error.localizedDescription)")
            .accessibilityHint("Tap dismiss to close")
        }
    }

    private func dismiss() {
        withAnimation {
            isVisible = false
        }
        onDismiss()
    }
}
