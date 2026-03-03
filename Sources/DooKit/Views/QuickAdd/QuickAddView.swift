import SwiftUI

struct QuickAddView: View {
    let onSubmit: (DooTask) -> Void
    let onDismiss: () -> Void

    @State private var input = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            TextField("Add a task...", text: $input)
                .textFieldStyle(.plain)
                .font(.system(size: 24, weight: .light))
                .focused($isFocused)
                .onSubmit {
                    guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let task = InlineSyntaxParser.parse(input)
                    onSubmit(task)
                    input = ""
                }
                .onExitCommand {
                    onDismiss()
                }

            HStack(spacing: 16) {
                hintItem("!0-2", label: "priority")
                hintItem("#tag", label: "tag")
                hintItem("@date", label: "or @tomorrow")
                hintItem("/text", label: "description")
            }
            .font(.caption)
            .foregroundStyle(DooStyle.textSecondary)
        }
        .padding(20)
        .frame(width: 520)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 16, y: 8)
        .onAppear {
            isFocused = true
        }
    }

    private func hintItem(_ code: String, label: String) -> some View {
        HStack(spacing: 2) {
            Text(code)
                .fontWeight(.medium)
                .foregroundStyle(DooStyle.textSecondary)
            Text(label)
        }
    }
}
