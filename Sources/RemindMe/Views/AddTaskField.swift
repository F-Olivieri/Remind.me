import SwiftUI

struct AddTaskField: View {
    @EnvironmentObject var store: TaskStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let selectedCategory: String?
    var compact = false
    @State private var text = ""
    @State private var categoryText = ""
    @State private var urgent = false
    @FocusState private var focused: Bool

    var body: some View {
        if compact {
            compactBody
        } else {
            fullBody
        }
    }

    private var fullBody: some View {
        VStack(spacing: Space.xs) {
            HStack(spacing: Space.xs + 2) {
                Image(systemName: "plus")
                    .foregroundStyle(.secondary)
                    .help("Type a task and press Return to add. Hold ⇧ for urgent.")
                TextField("Add a task... (Shift-Return for urgent)", text: $text)
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

            HStack(spacing: Space.xs) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                    .help("Category")
                TextField("Category", text: $categoryText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .onSubmit { submit() }
                if !store.categories.isEmpty {
                    Menu {
                        Button("No Category") { categoryText = "" }
                        Divider()
                        ForEach(store.categories, id: \.self) { category in
                            Button(category) { categoryText = category }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .help("Choose category")
                    .accessibilityLabel("Choose category")
                }
            }
        }
        .padding(Space.md - 2)
        .background(
            RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .onAppear {
            categoryText = selectedCategory ?? ""
            focused = true
        }
        .onChange(of: selectedCategory) { _, newValue in
            categoryText = newValue ?? ""
        }
    }

    private var compactBody: some View {
        HStack(spacing: Space.xs) {
            Image(systemName: "plus")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Capture anything...", text: $text)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($focused)
                .onSubmit { submit() }
                .onChange(of: text) { _, newValue in
                    UserDefaults.standard.set(newValue, forKey: AppSettings.captureDraftKey)
                }
            ForEach(quickCategories, id: \.self) { category in
                Button {
                    categoryText = category
                } label: {
                    Text(category)
                        .font(.caption2)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule(style: .continuous)
                                .fill(categoryText == category ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .help("Use \(category)")
                .accessibilityLabel("Use \(category)")
            }
            Menu {
                Button("No Category") { categoryText = "" }
                if !store.categories.isEmpty {
                    Divider()
                    ForEach(store.categories, id: \.self) { category in
                        Button(category) {
                            categoryText = category
                        }
                    }
                }
            } label: {
                Image(systemName: categoryText.isEmpty ? "folder" : "folder.fill")
                    .font(.caption)
                    .foregroundStyle(categoryText.isEmpty ? AnyShapeStyle(HierarchicalShapeStyle.secondary) : AnyShapeStyle(Color.accentColor))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help(categoryText.isEmpty ? "Choose category" : categoryText)
            .accessibilityLabel("Choose category")
            Button {
                settings.captureBarEnabled = false
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Hide capture bar")
            .accessibilityLabel("Hide capture bar")
        }
        .padding(.vertical, Space.sm)
        .padding(.horizontal, Space.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .padding(Space.xs)
        .contentShape(Rectangle())
        .onAppear {
            text = UserDefaults.standard.string(forKey: AppSettings.captureDraftKey) ?? ""
            categoryText = selectedCategory ?? ""
            focused = true
        }
    }

    private var quickCategories: [String] {
        let selected = categoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        var categories = store.categories
        if !selected.isEmpty && !categories.contains(selected) {
            categories.insert(selected, at: 0)
        }
        return Array(categories.prefix(3))
    }

    private func submit() {
        let isUrgent = urgent || NSEvent.modifierFlags.contains(.shift)
        let parsed = parseInlineCategory(text)
        withAnimation(Motion.respecting(reduceMotion, Motion.insert)) {
            store.add(title: parsed.title, urgent: isUrgent, category: parsed.category ?? categoryText)
        }
        text = ""
        UserDefaults.standard.set("", forKey: AppSettings.captureDraftKey)
        urgent = false
    }

    private func parseInlineCategory(_ raw: String) -> (title: String, category: String?) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("#") else {
            return (trimmed, nil)
        }

        let rest = trimmed.dropFirst()
        guard let separator = rest.firstIndex(where: { $0.isWhitespace }) else {
            return (trimmed, nil)
        }

        let category = String(rest[..<separator]).trimmingCharacters(in: .whitespacesAndNewlines)
        let title = String(rest[separator...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !category.isEmpty, !title.isEmpty else {
            return (trimmed, nil)
        }
        return (title, category)
    }
}
