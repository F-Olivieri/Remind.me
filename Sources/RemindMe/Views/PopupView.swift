import SwiftUI
import AppKit

struct PopupView: View {
    @EnvironmentObject var store: TaskStore
    @EnvironmentObject var windowController: FloatingWindowController
    @State private var showArchive = false

    var body: some View {
        VStack(spacing: 8) {
            header
            AddTaskField()
            Divider()
            taskList
            Divider()
            footer
        }
        .padding(10)
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
                windowController.toggle()
            } label: {
                Image(systemName: windowController.isOpen ? "pin.fill" : "pin")
                    .help(windowController.isOpen ? "Hide floating window" : "Keep on screen")
            }
            .buttonStyle(.plain)
            Menu {
                Button("Show Archive…") { showArchive = true }
                Divider()
                Button("Quit Remind.me") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }

    private var taskList: some View {
        Group {
            if store.visibleTasks.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.seal")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Nothing to do")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(store.visibleTasks) { t in
                            TaskRow(task: t)
                        }
                    }
                }
                .frame(maxHeight: 360)
            }
        }
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
