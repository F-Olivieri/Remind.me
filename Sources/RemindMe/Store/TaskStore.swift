import Foundation
import Combine

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [RTask] = []
    @Published private(set) var archive: [RTask] = []

    private let fileURL: URL
    private var saveTimer: Timer?
    private var archiveTimer: Timer?

    init() {
        let fm = FileManager.default
        let base = try! fm.url(for: .applicationSupportDirectory,
                               in: .userDomainMask,
                               appropriateFor: nil,
                               create: true)
            .appendingPathComponent("Remind.me", isDirectory: true)
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        self.fileURL = base.appendingPathComponent("data.json")
        load()
        rolloverCompletedToArchive()
        scheduleArchiveSweep()
    }

    // MARK: - Active tasks, sorted for UI

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

    func toggleComplete(_ id: UUID) {
        update(id) { $0.setComplete(!$0.isComplete) }
    }

    func toggleUrgent(_ id: UUID) {
        update(id) { $0.isUrgent.toggle() }
    }

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

    // MARK: - Archive rollover

    /// Move tasks completed before the start of today into archive.
    func rolloverCompletedToArchive(now: Date = Date()) {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)
        var moved: [RTask] = []
        tasks.removeAll { t in
            guard t.isComplete, let ca = t.completedAt else { return false }
            if ca < startOfToday {
                moved.append(t)
                return true
            }
            return false
        }
        if !moved.isEmpty {
            archive.append(contentsOf: moved)
            scheduleSave()
        }
    }

    private func scheduleArchiveSweep() {
        // Sweep every 10 minutes (covers day rollover for a long-running app).
        archiveTimer?.invalidate()
        archiveTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.rolloverCompletedToArchive() }
        }
    }

    // MARK: - Persistence

    private struct Persisted: Codable {
        var tasks: [RTask]
        var archive: [RTask]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(Persisted.self, from: data) else {
            return
        }
        self.tasks = decoded.tasks
        self.archive = decoded.archive
    }

    private func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { self?.save() }
        }
    }

    private func save() {
        let payload = Persisted(tasks: tasks, archive: archive)
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try enc.encode(payload)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("Remind.me save error: \(error)")
        }
    }
}
