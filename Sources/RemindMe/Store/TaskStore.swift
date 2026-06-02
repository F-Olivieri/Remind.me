import Foundation
import Combine

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [RTask] = []
    @Published private(set) var archive: [RTask] = []

    private(set) var folderURL: URL
    static let fileName = "RemindMe.json"
    static let legacyFileName = "data.json"
    private var fileURL: URL { folderURL.appendingPathComponent(Self.fileName) }
    private var legacyFileURL: URL { folderURL.appendingPathComponent(Self.legacyFileName) }

    private let saveSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(folderURL: URL) {
        self.folderURL = folderURL.standardized
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        migrateLegacyFileIfNeeded()
        load()
        setupSaveDebounce()
        rolloverCompletedToArchive()
        pruneArchive()
        scheduleSweep()
    }

    // MARK: - Visible / sorted

    var visibleTasks: [RTask] {
        tasks.sorted { a, b in
            if a.isUrgent != b.isUrgent { return a.isUrgent && !b.isUrgent }
            if a.isComplete != b.isComplete { return !a.isComplete && b.isComplete }
            return a.createdAt < b.createdAt
        }
    }

    // MARK: - Mutations

    func add(title: String, urgent: Bool = false) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(RTask(title: trimmed, isUrgent: urgent))
        scheduleSave()
    }

    func remove(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        scheduleSave()
    }

    func update(_ id: UUID, mutate: (inout RTask) -> Void) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        mutate(&tasks[idx])
        scheduleSave()
    }

    func toggleComplete(_ id: UUID) { update(id) { $0.setComplete(!$0.isComplete) } }
    func toggleUrgent(_ id: UUID)   { update(id) { $0.isUrgent.toggle() } }

    func rename(_ id: UUID, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        update(id) { $0.title = trimmed }
    }

    func unarchive(_ id: UUID) {
        guard let idx = archive.firstIndex(where: { $0.id == id }) else { return }
        var t = archive.remove(at: idx)
        t.setComplete(false)
        tasks.append(t)
        scheduleSave()
    }

    func deleteFromArchive(_ id: UUID) {
        archive.removeAll { $0.id == id }
        scheduleSave()
    }

    func clearArchive() {
        archive.removeAll()
        scheduleSave()
    }

    // MARK: - Archive rollover & retention

    func rolloverCompletedToArchive(now: Date = Date()) {
        let startOfToday = Calendar.current.startOfDay(for: now)
        var moved: [RTask] = []
        tasks.removeAll { t in
            guard t.isComplete else { return false }
            // Handle legacy/conflict tasks where completedAt is missing but isComplete is true
            let ca = t.completedAt ?? t.createdAt
            if ca < startOfToday {
                var updatedTask = t
                if updatedTask.completedAt == nil {
                    updatedTask.completedAt = ca
                }
                moved.append(updatedTask)
                return true
            }
            return false
        }
        if !moved.isEmpty {
            archive.append(contentsOf: moved)
            scheduleSave()
        }
    }

    /// Retention from UserDefaults: 0 = unlimited; otherwise prune archive entries
    /// whose completedAt is older than `retentionDays`.
    func pruneArchive(now: Date = Date()) {
        let days = UserDefaults.standard.integer(forKey: AppSettings.retentionKey)
        guard days > 0 else { return }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        let before = archive.count
        archive.removeAll { ($0.completedAt ?? .distantFuture) < cutoff }
        if archive.count != before { scheduleSave() }
    }

    private func scheduleSweep() {
        Timer.publish(every: 600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.rolloverCompletedToArchive()
                self?.pruneArchive()
            }
            .store(in: &cancellables)
    }

    // MARK: - Folder relocation

    /// Moves the database to a new folder. On success the new folder becomes authoritative.
    @discardableResult
    func relocate(to newFolder: URL) -> Bool {
        let canonicalNew = newFolder.resolvingSymlinksInPath().standardized
        let canonicalCurrent = folderURL.resolvingSymlinksInPath().standardized
        guard canonicalNew != canonicalCurrent else { return true }

        let fm = FileManager.default
        try? fm.createDirectory(at: canonicalNew, withIntermediateDirectories: true)
        let destination = canonicalNew.appendingPathComponent(Self.fileName)
        let source = fileURL
        do {
            if fm.fileExists(atPath: destination.path) {
                // Ensure we don't accidentally remove the source if they refer to the same folder via a hard/soft link
                guard destination.resolvingSymlinksInPath().standardized != source.resolvingSymlinksInPath().standardized else {
                    folderURL = canonicalNew
                    return true
                }
                try fm.removeItem(at: destination)
            }
            if fm.fileExists(atPath: source.path) {
                try fm.moveItem(at: source, to: destination)
            } else {
                // Nothing to move; write the current in-memory state to the new location.
                try writeAtomically(to: destination)
            }
            folderURL = canonicalNew
            return true
        } catch {
            NSLog("Remind.me relocate error: \(error)")
            return false
        }
    }

    // MARK: - Persistence

    private struct Persisted: Codable {
        var tasks: [RTask]
        var archive: [RTask]
    }

    private func migrateLegacyFileIfNeeded() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: legacyFileURL.path),
              !fm.fileExists(atPath: fileURL.path) else { return }
        do {
            try fm.moveItem(at: legacyFileURL, to: fileURL)
        } catch {
            NSLog("Remind.me legacy migration error: \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(Persisted.self, from: data) else {
            return
        }
        self.tasks = decoded.tasks
        self.archive = decoded.archive
    }

    private func setupSaveDebounce() {
        saveSubject
            .debounce(for: .seconds(0.4), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.save()
            }
            .store(in: &cancellables)
    }

    private func scheduleSave() {
        saveSubject.send()
    }

    private func save() {
        do { try writeAtomically(to: fileURL) }
        catch { NSLog("Remind.me save error: \(error)") }
    }

    private func writeAtomically(to url: URL) throws {
        let payload = Persisted(tasks: tasks, archive: archive)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try enc.encode(payload)
        try data.write(to: url, options: .atomic)
    }
}
