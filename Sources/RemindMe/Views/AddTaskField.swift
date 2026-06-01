import SwiftUI

struct AddTaskField: View {
    @EnvironmentObject var store: TaskStore
    @State private var text = ""
    @State private var urgent = false
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus")
                .foregroundStyle(.secondary)
            TextField("Add task… (⇧⏎ for urgent)", text: $text)
                .textFieldStyle(.plain)
                .focused($focused)
                .onSubmit { submit() }
            Button {
                urgent.toggle()
            } label: {
                Image(systemName: urgent ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                    .foregroundStyle(urgent ? .orange : .secondary)
            }
            .buttonStyle(.plain)
            .help("Mark next task as urgent")
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.08))
        )
        .onAppear { focused = true }
    }

    private func submit() {
        let isUrgent = urgent || NSEvent.modifierFlags.contains(.shift)
        store.add(title: text, urgent: isUrgent)
        text = ""
        urgent = false
    }
}
