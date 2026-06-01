import SwiftUI

struct TaskRow: View {
    @EnvironmentObject var store: TaskStore
    let task: RTask

    @State private var editing = false
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { store.toggleComplete(task.id) }) {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isComplete ? AnyShapeStyle(HierarchicalShapeStyle.secondary) : AnyShapeStyle(Color.accentColor))
                    .font(.system(size: 16, weight: .regular))
            }
            .buttonStyle(.plain)

            if editing {
                TextField("", text: $draft, onCommit: commit)
                    .textFieldStyle(.plain)
                    .focused($focused)
                    .onExitCommand { editing = false }
            } else {
                Text(task.title)
                    .strikethrough(task.isComplete, color: .secondary)
                    .foregroundStyle(task.isComplete ? .secondary : .primary)
                    .lineLimit(2)
                    .onTapGesture(count: 2) { startEdit() }
            }

            Spacer(minLength: 4)

            if task.isUrgent {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            Menu {
                Button(task.isUrgent ? "Unpin" : "Pin as Urgent") {
                    store.toggleUrgent(task.id)
                }
                Button("Edit") { startEdit() }
                Divider()
                Button("Delete", role: .destructive) { store.remove(task.id) }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(task.isUrgent ? Color.orange.opacity(0.08) : Color.clear)
        )
        .opacity(task.isComplete ? 0.55 : 1.0)
    }

    private func startEdit() {
        draft = task.title
        editing = true
        DispatchQueue.main.async { focused = true }
    }

    private func commit() {
        store.rename(task.id, to: draft)
        editing = false
    }
}
