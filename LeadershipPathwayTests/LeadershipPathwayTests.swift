import XCTest
@testable import LeadershipPathway

final class ReadingPlanTests: XCTestCase {
    func testBundledPlanHas34WeeksOfFiveDays() {
        let plan = ReadingPlan.bundled
        XCTAssertEqual(plan.weeks.map(\.number), Array(1...34))
        XCTAssertTrue(plan.weeks.allSatisfy { $0.days.count == 5 })
        XCTAssertEqual(plan.allDays.count, 170)
    }

    func testPassagesAreCategorised() throws {
        let day = try XCTUnwrap(ReadingPlan.bundled.day(DayID(week: 16, day: 3)))
        XCTAssertEqual(day.passages.map(\.displayName), ["Ephesians 1–2", "Psalms 77", "Psalms 78:1–25"])
        XCTAssertEqual(day.passages.map(\.category), [.newTestament, .psalms, .psalms])
    }

    func testBookOnlyPassagesHaveNoReference() throws {
        let day = try XCTUnwrap(ReadingPlan.bundled.day(DayID(week: 31, day: 4)))
        XCTAssertEqual(day.passages.map(\.displayName), ["2 John", "3 John", "Proverbs 29:3–12"])
    }
}

@MainActor
final class ProgressStoreTests: XCTestCase {
    private let storageURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func makeStore(now: Date = Date()) -> ProgressStore {
        let url = storageURL
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return ProgressStore(plan: .bundled, storageURL: storageURL, calendar: calendar, now: { now })
    }

    private func date(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string + "T12:00:00Z")!
    }

    func testDayCompletesOnlyWhenAllPassagesRead() {
        let store = makeStore()
        let day = store.plan.allDays[0]
        store.togglePassage(day, index: 0)
        XCTAssertFalse(store.isComplete(day))
        XCTAssertEqual(store.nextDay?.id, day.id)

        store.togglePassage(day, index: 1)
        XCTAssertTrue(store.isComplete(day))
        XCTAssertEqual(store.nextDay?.id, DayID(week: 1, day: 2))

        store.togglePassage(day, index: 1)
        XCTAssertFalse(store.isComplete(day))
    }

    func testProgressPersistsAcrossInstances() {
        let day = ReadingPlan.bundled.allDays[3]
        do {
            let store = makeStore()
            store.setDay(day, complete: true)
            store.setNote("Lead by serving", for: day)
        }
        let reloaded = makeStore()
        XCTAssertTrue(reloaded.isComplete(day))
        XCTAssertEqual(reloaded.note(for: day), "Lead by serving")
    }

    func testStreakCountsConsecutiveCalendarDays() {
        var today = date("2026-10-19")
        let store = ProgressStore(plan: .bundled, storageURL: storageURL, calendar: calendar, now: { today })
        let url = storageURL
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        let days = store.plan.allDays
        for (offset, day) in days.prefix(3).enumerated() {
            today = date("2026-10-1\(7 + offset)")
            store.setDay(day, complete: true)
        }
        today = date("2026-10-19")
        XCTAssertEqual(store.currentStreak, 3)
        today = date("2026-10-20")
        XCTAssertEqual(store.currentStreak, 3, "a streak survives until the end of the next day")
        today = date("2026-10-21")
        XCTAssertEqual(store.currentStreak, 0)
    }

    func testScheduleStatusUsesFiveDaysPerWeek() {
        let store = makeStore(now: date("2026-10-19"))
        XCTAssertEqual(store.scheduleStatus, .notStarted)

        store.setStartDate(date("2026-10-12")) // 7 days ago → second week, first day
        XCTAssertEqual(store.expectedCompletedDays, 6)
        XCTAssertEqual(store.scheduleStatus, .behind(6))

        for day in store.plan.allDays.prefix(7) { store.setDay(day, complete: true) }
        XCTAssertEqual(store.scheduleStatus, .ahead(1))
    }

    func testResetKeepsStartDate() {
        let store = makeStore()
        store.setStartDate(date("2026-10-01"))
        store.setDay(store.plan.allDays[0], complete: true)
        store.resetProgress()
        XCTAssertEqual(store.completedDays, 0)
        XCTAssertNotNil(store.startDate)
    }
}
