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
    @State private var selectedCategory: String? = nil

    /// True when this view is hosted inside the menu-bar popover; flips the
    /// pin behaviour to dismiss the popover and open the floating window
    /// instead of toggling pin state in-place.
    var inMenuBar: Bool = false

    var body: some View {
        Group {
            if settings.captureBarEnabled && !inMenuBar {
                AddTaskField(selectedCategory: selectedCategory, compact: true)
                    .environmentObject(settings)
                    .frame(width: 560)
            } else {
                VStack(spacing: Space.sm) {
                    header
                    categoryBar
                    Divider()
                    taskList
                    Divider()
                    footer
                    AddTaskField(selectedCategory: selectedCategory)
                }
                .padding(Space.md)
                .frame(width: 340)
                .frame(minHeight: 240)
            }
        }
        .onChange(of: settings.captureBarEnabled) { _, visible in
            if !inMenuBar {
                pinController.setCaptureBarVisible(visible)
            }
        }
        .onAppear {
            if !inMenuBar {
                pinController.setCaptureBarVisible(settings.captureBarEnabled)
            }
        }
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
                Button(settings.captureBarEnabled ? "Hide Capture Bar" : "Show Capture Bar") {
                    settings.captureBarEnabled.toggle()
                }
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
            if filteredTasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(filteredTasks) { t in
                            TaskRow(task: t)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                                    removal: .opacity
                                ))
                        }
                    }
                    .animation(Motion.respecting(reduceMotion, Motion.settle), value: filteredTasks)
                }
                .frame(maxHeight: 360)
            }
        }
    }

    private var filteredTasks: [RTask] {
        store.visibleTasks(in: selectedCategory)
    }

    @ViewBuilder
    private var categoryBar: some View {
        if !store.categories.isEmpty {
            HStack(spacing: Space.xs) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Menu {
                    Button("All Categories") { selectedCategory = nil }
                    Divider()
                    ForEach(store.categories, id: \.self) { category in
                        Button(category) { selectedCategory = category }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCategory ?? "All Categories")
                            .font(.caption)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Filter by category")
                Spacer()
                if selectedCategory != nil {
                    Button {
                        selectedCategory = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear category filter")
                    .accessibilityLabel("Clear category filter")
                }
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
            let remaining = store.openCount(in: selectedCategory)
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
