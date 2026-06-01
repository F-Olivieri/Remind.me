import SwiftUI
import AppKit

struct PopupView: View {
    @EnvironmentObject var store: TaskStore
    @EnvironmentObject var windowController: FloatingWindowController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showArchive = false

    var body: some View {
        VStack(spacing: Space.sm) {
            header
            AddTaskField()
            Divider()
            taskList
            Divider()
            footer
        }
        .padding(Space.md)
        .frame(width: 340)
        .frame(minHeight: 240)
        .sheet(isPresented: $showArchive) {
            ArchiveView(isPresented: $showArchive)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack {
            Text("Remind.me").font(.headline)
            Spacer()
            Button {
                withAnimation(Motion.respecting(reduceMotion, Motion.window)) {
                    windowController.toggle()
                }
            } label: {
                Image(systemName: windowController.isOpen ? "pin.fill" : "pin")
                    .foregroundStyle(windowController.isOpen ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
            }
            .buttonStyle(.plain)
            .help(windowController.isOpen ? "Unpin window" : "Keep on screen")
            .accessibilityLabel(windowController.isOpen ? "Unpin window" : "Keep on screen")
            .accessibilityHint(windowController.isOpen ? "Returns to the menu bar" : "Detaches as a floating window")

            Menu {
                Button("Show Archive…") { showArchive = true }
                Divider()
                Button("Quit Remind.me") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel("Menu")
        }
    }

    private var taskList: some View {
        Group {
            if store.visibleTasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(store.visibleTasks) { t in
                            TaskRow(task: t)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                                    removal: .opacity
                                ))
                        }
                    }
                    .animation(Motion.respecting(reduceMotion, Motion.settle), value: store.visibleTasks)
                }
                .frame(maxHeight: 360)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Space.xs) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("All clear")
                .font(.headline)
            Text("Nothing on your plate right now.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding(.vertical, Space.lg)
    }

    private var footer: some View {
        HStack {
            let remaining = store.tasks.filter { !$0.isComplete }.count
            Text("\(remaining) open")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Archive…") { showArchive = true }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
