import SwiftUI

struct DeleteButtonCell: View {
    let onDelete: () -> Void

    var body: some View {
        Button(action: onDelete) {
            Image(systemName: "xmark")
                .font(.caption.weight(.medium))
        }
        .buttonStyle(.plain)
        .foregroundStyle(DooStyle.textSecondary)
    }
}
