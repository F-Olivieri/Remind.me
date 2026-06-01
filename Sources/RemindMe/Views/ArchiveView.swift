import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var store: TaskStore
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Archive").font(.headline)
                Spacer()
                Button("Done") { isPresented = false }
                    .keyboardShortcut(.defaultAction)
            }
            Divider()
            if store.archive.isEmpty {
                Text("Archive is empty")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(store.archive.sorted(by: { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) })) { t in
                            archiveRow(t)
                        }
                    }
                }
                .frame(maxHeight: 380)
            }
            Divider()
            HStack {
                Spacer()
                Button("Clear All", role: .destructive) {
                    store.clearArchive()
                }
                .disabled(store.archive.isEmpty)
            }
        }
        .padding(12)
        .frame(width: 380, height: 460)
    }

    @ViewBuilder
    private func archiveRow(_ t: RTask) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(t.title)
                if let ca = t.completedAt {
                    Text(ca, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Restore") { store.unarchive(t.id) }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.accentColor)
            Button {
                store.deleteFromArchive(t.id)
            } label: {
                Image(systemName: "trash").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
    }
}
