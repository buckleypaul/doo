import SwiftUI

struct CompleteButtonCell: View {
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                .font(.body.weight(.regular))
                .foregroundStyle(isCompleted ? Color.green : Color.secondary)
        }
        .buttonStyle(.plain)
    }
}
