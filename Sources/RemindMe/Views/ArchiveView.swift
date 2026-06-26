import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var store: TaskStore
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: Space.sm) {
            HStack {
                Text("Archive").font(.headline)
                Spacer()
                Button("Done") { isPresented = false }
                    .keyboardShortcut(.defaultAction)
            }
            Divider()
            if store.archive.isEmpty {
                VStack(spacing: Space.xs) {
                    Image(systemName: "tray")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("Archive is empty")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(sortedArchive) { t in
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
        .padding(Space.md)
        .frame(width: 380, height: 460)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous))
    }

    private var sortedArchive: [RTask] {
        store.archive.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    @ViewBuilder
    private func archiveRow(_ t: RTask) -> some View {
        HStack(spacing: Space.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.secondary)
                .help("Completed task")
            VStack(alignment: .leading, spacing: 1) {
                Text(t.title).font(.body)
                if let category = t.category {
                    Text(category)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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
            .help("Delete forever")
        }
        .padding(.vertical, Space.xs)
        .padding(.horizontal, Space.sm - 2)
        .background(
            RoundedRectangle(cornerRadius: Radius.row, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}
