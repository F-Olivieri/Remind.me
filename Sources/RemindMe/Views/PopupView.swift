import SwiftUI
import AppKit

struct PopupView: View {
    @EnvironmentObject var store: TaskStore
    @EnvironmentObject var pinController: PinController
    @EnvironmentObject var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openWindow) private var openWindow
    @State private var showArchive = false
    @State private var showSettings = false

    /// True when this view is hosted inside the menu-bar popover; flips the
    /// pin behaviour to dismiss the popover and open the floating window
    /// instead of toggling pin state in-place.
    var inMenuBar: Bool = false

    var body: some View {
        VStack(spacing: Space.sm) {
            header
            Divider()
            taskList
            Divider()
            footer
            AddTaskField()
        }
        .padding(Space.md)
        .frame(width: 340)
        .frame(minHeight: 240)
        .sheet(isPresented: $showArchive) {
            ArchiveView(isPresented: $showArchive)
                .environmentObject(store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
                .environmentObject(settings)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack {
            Text("Remind.me").font(.headline)
            Spacer()
            Button {
                if inMenuBar {
                    pinController.pinFromMenuBar { openWindow(id: $0) }
                } else {
                    withAnimation(Motion.respecting(reduceMotion, Motion.window)) {
                        pinController.togglePin()
                    }
                }
            } label: {
                Image(systemName: pinController.isPinned ? "pin.fill" : "pin")
                    .foregroundStyle(pinController.isPinned ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
            }
            .buttonStyle(.plain)
            .help(pinController.isPinned ? "Unpin — return to normal stacking" : "Keep on top of every other window")
            .accessibilityLabel(pinController.isPinned ? "Unpin window" : "Keep on top")
            .accessibilityHint(pinController.isPinned ? "Returns to normal window stacking" : "Pins this window above all other apps")

            Menu {
                Button("Show Archive…") { showArchive = true }
                Divider()
                Button("Settings…") { showSettings = true }
                Divider()
                Button("Quit Remind.me") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Archive, settings, quit")
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
