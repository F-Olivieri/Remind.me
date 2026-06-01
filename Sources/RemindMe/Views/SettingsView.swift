import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: TaskStore
    @Binding var isPresented: Bool

    @State private var retentionChoice: RetentionChoice = .unlimited
    @State private var customDays: Int = 7

    var body: some View {
        VStack(spacing: Space.md) {
            HStack {
                Text("Settings").font(.headline)
                Spacer()
                Button("Done") { isPresented = false }
                    .keyboardShortcut(.defaultAction)
            }
            Divider()

            Form {
                Section("General") {
                    Toggle("Show Dock Icon", isOn: $settings.showDockIcon)
                        .help("Show or hide Remind.me in the Dock")
                }

                Section("Database") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Folder").font(.subheadline)
                            Text(settings.dbFolderURL.path)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Button("Change…") { chooseFolder() }
                        Button("Default") { resetFolder() }
                            .help("Reset to Application Support/Remind.me")
                    }
                }

                Section("Archive retention") {
                    Picker("Keep completed tasks for", selection: $retentionChoice) {
                        Text("1 day").tag(RetentionChoice.oneDay)
                        Text("30 days").tag(RetentionChoice.thirtyDays)
                        Text("Unlimited").tag(RetentionChoice.unlimited)
                        Text("Custom…").tag(RetentionChoice.custom)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: retentionChoice) { _, newValue in
                        applyRetention(newValue)
                    }

                    if retentionChoice == .custom {
                        HStack {
                            Text("Days:")
                            Stepper(value: $customDays, in: 1...365) {
                                Text("\(customDays)")
                                    .frame(minWidth: 30, alignment: .trailing)
                                    .monospacedDigit()
                            }
                            .onChange(of: customDays) { _, days in
                                settings.retentionDays = days
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .padding(Space.md)
        .frame(width: 460, height: 460)
        .onAppear { loadRetentionFromSettings() }
    }

    // MARK: - Retention plumbing

    enum RetentionChoice: Hashable { case oneDay, thirtyDays, unlimited, custom }

    private func loadRetentionFromSettings() {
        switch settings.retentionDays {
        case 0:  retentionChoice = .unlimited
        case 1:  retentionChoice = .oneDay
        case 30: retentionChoice = .thirtyDays
        default:
            retentionChoice = .custom
            customDays = max(1, settings.retentionDays)
        }
    }

    private func applyRetention(_ choice: RetentionChoice) {
        switch choice {
        case .oneDay:     settings.retentionDays = 1
        case .thirtyDays: settings.retentionDays = 30
        case .unlimited:  settings.retentionDays = 0
        case .custom:     settings.retentionDays = customDays
        }
    }

    // MARK: - Folder picker

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Choose where Remind.me should keep its task database (data.json)."
        panel.directoryURL = settings.dbFolderURL
        if panel.runModal() == .OK, let url = panel.url {
            // Trigger relocate via AppSettings closure (wired in RemindMeApp).
            settings.dbFolderURL = url
        }
    }

    private func resetFolder() {
        let defaultURL = AppSettings.defaultDbFolder()
        settings.dbFolderURL = defaultURL
        UserDefaults.standard.removeObject(forKey: AppSettings.dbFolderKey)
    }
}
