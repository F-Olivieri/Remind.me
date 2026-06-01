import SwiftUI

struct TaskRow: View {
    @EnvironmentObject var store: TaskStore
    let task: RTask

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editing = false
    @State private var draft = ""
    @State private var hovering = false
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: Space.sm) {
            checkbox

            if editing {
                TextField("", text: $draft, onCommit: commit)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($focused)
                    .onExitCommand { editing = false }
            } else {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isComplete, color: .secondary)
                    .foregroundStyle(task.isComplete ? AnyShapeStyle(HierarchicalShapeStyle.secondary) : AnyShapeStyle(HierarchicalShapeStyle.primary))
                    .lineLimit(2)
                    .onTapGesture(count: 2) { startEdit() }
            }

            Spacer(minLength: 4)

            if task.isUrgent {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.rmUrgent)
                    .font(.caption)
                    .accessibilityHidden(true)
            }

            actionsMenu
                .opacity(hovering || task.isUrgent ? 1 : 0.0)
                .animation(.easeInOut(duration: 0.12), value: hovering)
        }
        .padding(.vertical, Space.xs)
        .padding(.horizontal, Space.sm)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
        .overlay(alignment: .leading) {
            if task.isUrgent {
                RoundedRectangle(cornerRadius: 1.25)
                    .fill(Color.rmUrgent)
                    .frame(width: 2.5)
                    .padding(.vertical, 2)
                    .transition(.opacity)
            }
        }
        .opacity(task.isComplete ? 0.55 : 1.0)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(Motion.respecting(reduceMotion, Motion.tint), value: task.isUrgent)
        .animation(Motion.respecting(reduceMotion, Motion.complete), value: task.isComplete)
    }

    // MARK: - Pieces

    private var checkbox: some View {
        Button {
            withAnimation(Motion.respecting(reduceMotion, Motion.complete)) {
                store.toggleComplete(task.id)
            }
        } label: {
            Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.isComplete
                                 ? AnyShapeStyle(HierarchicalShapeStyle.secondary)
                                 : AnyShapeStyle(Color.accentColor))
                .font(.system(size: 18, weight: .regular))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(task.isComplete ? "Completed" : "Not completed")
        .accessibilityValue(task.title)
        .accessibilityHint("Double-tap to toggle completion")
        .accessibilityAddTraits(task.isComplete ? .isSelected : [])
    }

    private var actionsMenu: some View {
        Menu {
            Button(task.isUrgent ? "Unpin" : "Pin as Urgent") {
                withAnimation(Motion.respecting(reduceMotion, Motion.settle)) {
                    store.toggleUrgent(task.id)
                }
            }
            Button("Edit") { startEdit() }
            Divider()
            Button("Delete", role: .destructive) {
                withAnimation(Motion.respecting(reduceMotion, Motion.settle)) {
                    store.remove(task.id)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel("Task actions")
    }

    @ViewBuilder
    private var rowBackground: some View {
        if task.isUrgent {
            Color.rmUrgent.opacity(0.11)
        } else if hovering {
            Color.primary.opacity(0.06)
        } else {
            Color.clear
        }
    }

    // MARK: - Edit

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
