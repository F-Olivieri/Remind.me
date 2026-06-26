import SwiftUI
import AppKit

@MainActor
final class AppSettings: ObservableObject {
    static let dockKey       = "showDockIcon"
    static let retentionKey  = "archiveRetentionDays"      // 0 = unlimited
    static let dbFolderKey   = "dbFolderBookmark"          // Data (security-scoped bookmark)
    static let dbFolderPathKey = "dbFolderPath"            // String (display + fallback)
    static let captureBarKey = "captureBarEnabled"
    static let captureDraftKey = "captureDraft"

    @Published var showDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(showDockIcon, forKey: Self.dockKey)
            applyActivationPolicy()
        }
    }

    /// 0 = unlimited; otherwise number of days completed tasks remain in the archive.
    @Published var retentionDays: Int {
        didSet {
            UserDefaults.standard.set(retentionDays, forKey: Self.retentionKey)
            onRetentionChange?(retentionDays)
        }
    }

    @Published var dbFolderURL: URL {
        didSet {
            persistDbFolder()
            onDbFolderChange?(dbFolderURL)
        }
    }

    @Published var captureBarEnabled: Bool {
        didSet {
            UserDefaults.standard.set(captureBarEnabled, forKey: Self.captureBarKey)
        }
    }

    /// Closures wired by the app at launch so this store stays decoupled.
    var onDbFolderChange: ((URL) -> Void)?
    var onRetentionChange: ((Int) -> Void)?

    init() {
        let d = UserDefaults.standard
        if d.object(forKey: Self.dockKey) == nil { d.set(true, forKey: Self.dockKey) }
        if d.object(forKey: Self.retentionKey) == nil { d.set(0, forKey: Self.retentionKey) }
        if d.object(forKey: Self.captureBarKey) == nil { d.set(true, forKey: Self.captureBarKey) }
        self.showDockIcon = d.bool(forKey: Self.dockKey)
        self.retentionDays = d.integer(forKey: Self.retentionKey)
        self.dbFolderURL = AppSettings.resolveDbFolder()
        self.captureBarEnabled = d.bool(forKey: Self.captureBarKey)
    }

    // MARK: - Activation policy

    func applyActivationPolicy() {
        let target: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        guard NSApp.activationPolicy() != target else { return }
        NSApp.setActivationPolicy(target)
        if target == .regular {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - DB folder persistence

    static func defaultDbFolder() -> URL {
        let base = try! FileManager.default.url(for: .applicationSupportDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true)
            .appendingPathComponent("Remind.me", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static func resolveDbFolder() -> URL {
        let d = UserDefaults.standard
        if let data = d.data(forKey: dbFolderKey) {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: data,
                                  options: [.withSecurityScope],
                                  relativeTo: nil,
                                  bookmarkDataIsStale: &stale),
               FileManager.default.fileExists(atPath: url.path) {
                _ = url.startAccessingSecurityScopedResource()
                return url
            }
        }
        if let path = d.string(forKey: dbFolderPathKey),
           FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return defaultDbFolder()
    }

    private func persistDbFolder() {
        let d = UserDefaults.standard
        d.set(dbFolderURL.path, forKey: Self.dbFolderPathKey)
        if let data = try? dbFolderURL.bookmarkData(options: [.withSecurityScope],
                                                    includingResourceValuesForKeys: nil,
                                                    relativeTo: nil) {
            d.set(data, forKey: Self.dbFolderKey)
        }
    }

    func resetDbFolderToDefault() {
        dbFolderURL = AppSettings.defaultDbFolder()
        UserDefaults.standard.removeObject(forKey: Self.dbFolderKey)
    }
}
