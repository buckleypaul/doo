import SwiftUI

struct DeleteButtonCell: View {
    let isHovered: Bool
    let onDelete: () -> Void

    var body: some View {
        Group {
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
