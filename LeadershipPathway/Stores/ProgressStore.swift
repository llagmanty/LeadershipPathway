import Foundation

/// Everything the user has done, persisted as a single JSON file.
struct ProgressSnapshot: Codable, Equatable {
    var completedPassages: Set<String> = []
    /// Day key ("w3d2") → when the last passage of that day was checked off.
    var dayCompletionDates: [String: Date] = [:]
    var notes: [String: String] = [:]
    var startDate: Date?
}

/// Where the reader stands relative to a five-sessions-per-week pace from their start date.
enum ScheduleStatus: Equatable {
    case notStarted
    case onTrack
    case ahead(Int)
    case behind(Int)
}

@MainActor
final class ProgressStore: ObservableObject {
    let plan: ReadingPlan

    @Published private(set) var snapshot: ProgressSnapshot {
        didSet { save() }
    }

    private let storageURL: URL
    private let calendar: Calendar
    private let now: () -> Date

    init(
        plan: ReadingPlan,
        storageURL: URL = ProgressStore.defaultStorageURL,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.plan = plan
        self.storageURL = storageURL
        self.calendar = calendar
        self.now = now
        if let data = try? Data(contentsOf: storageURL),
           let saved = try? JSONDecoder().decode(ProgressSnapshot.self, from: data) {
            snapshot = saved
        } else {
            snapshot = ProgressSnapshot()
        }
    }

    nonisolated static var defaultStorageURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("progress.json")
    }

    // MARK: - Passages and days

    func isComplete(_ day: ReadingDay, passage index: Int) -> Bool {
        snapshot.completedPassages.contains(day.passageKey(index))
    }

    func togglePassage(_ day: ReadingDay, index: Int) {
        setPassage(day, index: index, complete: !isComplete(day, passage: index))
    }

    func setPassage(_ day: ReadingDay, index: Int, complete: Bool) {
        var updated = snapshot
        if complete {
            updated.completedPassages.insert(day.passageKey(index))
        } else {
            updated.completedPassages.remove(day.passageKey(index))
        }
        updateDayCompletion(day, in: &updated)
        snapshot = updated
    }

    func setDay(_ day: ReadingDay, complete: Bool) {
        var updated = snapshot
        for index in day.passages.indices {
            if complete {
                updated.completedPassages.insert(day.passageKey(index))
            } else {
                updated.completedPassages.remove(day.passageKey(index))
            }
        }
        updateDayCompletion(day, in: &updated)
        snapshot = updated
    }

    func isComplete(_ day: ReadingDay) -> Bool {
        snapshot.dayCompletionDates[day.id.key] != nil
    }

    func completionDate(of day: ReadingDay) -> Date? {
        snapshot.dayCompletionDates[day.id.key]
    }

    func completedPassageCount(_ day: ReadingDay) -> Int {
        day.passages.indices.filter { isComplete(day, passage: $0) }.count
    }

    func dayFraction(_ day: ReadingDay) -> Double {
        guard !day.passages.isEmpty else { return 0 }
        return Double(completedPassageCount(day)) / Double(day.passages.count)
    }

    private func updateDayCompletion(_ day: ReadingDay, in snapshot: inout ProgressSnapshot) {
        let allDone = day.passages.indices.allSatisfy { snapshot.completedPassages.contains(day.passageKey($0)) }
        if allDone {
            if snapshot.dayCompletionDates[day.id.key] == nil {
                snapshot.dayCompletionDates[day.id.key] = now()
            }
        } else {
            snapshot.dayCompletionDates[day.id.key] = nil
        }
    }

    // MARK: - Notes

    func note(for day: ReadingDay) -> String {
        snapshot.notes[day.id.key] ?? ""
    }

    func setNote(_ text: String, for day: ReadingDay) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        snapshot.notes[day.id.key] = trimmed.isEmpty ? nil : text
    }

    // MARK: - Weeks

    func completedDayCount(_ week: ReadingWeek) -> Int {
        week.days.filter { isComplete($0) }.count
    }

    func isComplete(_ week: ReadingWeek) -> Bool {
        week.days.allSatisfy { isComplete($0) }
    }

    func weekFraction(_ week: ReadingWeek) -> Double {
        let total = week.days.reduce(0) { $0 + $1.passages.count }
        guard total > 0 else { return 0 }
        let done = week.days.reduce(0) { $0 + completedPassageCount($1) }
        return Double(done) / Double(total)
    }

    // MARK: - Overall progress

    /// The first day in plan order that still has unread passages, or nil when the plan is finished.
    var nextDay: ReadingDay? {
        plan.allDays.first { !isComplete($0) }
    }

    var completedDays: Int { snapshot.dayCompletionDates.count }
    var totalDays: Int { plan.allDays.count }
    var completedWeeks: Int { plan.weeks.filter { isComplete($0) }.count }

    var overallFraction: Double {
        let total = plan.totalPassages
        guard total > 0 else { return 0 }
        return Double(snapshot.completedPassages.count) / Double(total)
    }

    func fraction(for category: PassageCategory) -> Double {
        var total = 0
        var done = 0
        for day in plan.allDays {
            for (index, passage) in day.passages.enumerated() where passage.category == category {
                total += 1
                if isComplete(day, passage: index) { done += 1 }
            }
        }
        return total == 0 ? 0 : Double(done) / Double(total)
    }

    /// Consecutive calendar days, ending today (or yesterday), on which at least one reading day was finished.
    var currentStreak: Int {
        let activeDays = Set(snapshot.dayCompletionDates.values.map { calendar.startOfDay(for: $0) })
        var cursor = calendar.startOfDay(for: now())
        if !activeDays.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  activeDays.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while activeDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    // MARK: - Schedule

    var startDate: Date? { snapshot.startDate }

    func setStartDate(_ date: Date?) {
        snapshot.startDate = date.map { calendar.startOfDay(for: $0) }
    }

    /// Number of sessions that should be done by today: five per seven calendar days, starting on the start date.
    var expectedCompletedDays: Int? {
        guard let start = snapshot.startDate else { return nil }
        let elapsed = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: now())).day ?? 0
        guard elapsed >= 0 else { return 0 }
        let expected = (elapsed / 7) * 5 + min(elapsed % 7 + 1, 5)
        return min(expected, totalDays)
    }

    var scheduleStatus: ScheduleStatus {
        guard let expected = expectedCompletedDays else { return .notStarted }
        let difference = completedDays - expected
        if difference > 0 { return .ahead(difference) }
        if difference < 0 { return .behind(-difference) }
        return .onTrack
    }

    // MARK: - Reset

    func resetProgress() {
        snapshot = ProgressSnapshot(startDate: snapshot.startDate)
    }

    // MARK: - Persistence

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
}
