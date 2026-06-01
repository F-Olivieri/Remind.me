import SwiftUI

struct AddTaskField: View {
    @EnvironmentObject var store: TaskStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var text = ""
    @State private var urgent = false
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: Space.xs + 2) {
            Image(systemName: "plus")
                .foregroundStyle(.secondary)
                .help("Type a task and press Return to add. Hold ⇧ for urgent.")
            TextField("Add a task… (⇧⏎ for urgent)", text: $text)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($focused)
                .onSubmit { submit() }
            Button {
                urgent.toggle()
            } label: {
                Image(systemName: urgent ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                    .foregroundStyle(urgent ? AnyShapeStyle(Color.rmUrgent) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
            }
            .buttonStyle(.plain)
            .help(urgent ? "Next task will be urgent — click to undo" : "Mark next task as urgent (pinned to top)")
            .accessibilityLabel(urgent ? "Urgent, on" : "Mark urgent")
            .accessibilityHint("Pins this task to the top")
        }
        .padding(Space.md - 2)
        .background(
            RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .onAppear { focused = true }
    }

    private func submit() {
        let isUrgent = urgent || NSEvent.modifierFlags.contains(.shift)
        withAnimation(Motion.respecting(reduceMotion, Motion.insert)) {
            store.add(title: text, urgent: isUrgent)
        }
        text = ""
        urgent = false
    }
}
