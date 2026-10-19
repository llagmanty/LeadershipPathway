import Foundation

/// The three reading tracks that run in parallel through the plan.
enum PassageCategory: String, Codable, CaseIterable, Identifiable {
    case newTestament
    case psalms
    case proverbs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newTestament: "New Testament"
        case .psalms: "Psalms"
        case .proverbs: "Proverbs"
        }
    }

    var symbol: String {
        switch self {
        case .newTestament: "book.closed.fill"
        case .psalms: "music.note"
        case .proverbs: "lightbulb.fill"
        }
    }
}

struct Passage: Codable, Hashable {
    let book: String
    let abbreviation: String
    let reference: String
    let category: PassageCategory

    var displayName: String {
        reference.isEmpty ? book : "\(book) \(reference)"
    }
}

struct DayID: Hashable, Codable, Comparable {
    let week: Int
    let day: Int

    var key: String { "w\(week)d\(day)" }

    static func < (lhs: DayID, rhs: DayID) -> Bool {
        (lhs.week, lhs.day) < (rhs.week, rhs.day)
    }
}

struct ReadingDay: Identifiable, Hashable {
    let week: Int
    let number: Int
    let reading: String
    let passages: [Passage]

    var id: DayID { DayID(week: week, day: number) }
    var title: String { "Week \(week) · Day \(number)" }

    func passageKey(_ index: Int) -> String { "\(id.key)p\(index)" }
}

struct ReadingWeek: Identifiable, Hashable {
    let number: Int
    let summary: String
    let days: [ReadingDay]

    var id: Int { number }
}

struct ReadingPlan {
    let title: String
    let subtitle: String
    let weeks: [ReadingWeek]

    var allDays: [ReadingDay] { weeks.flatMap(\.days) }
    var totalPassages: Int { allDays.reduce(0) { $0 + $1.passages.count } }

    func week(_ number: Int) -> ReadingWeek? {
        weeks.first { $0.number == number }
    }

    func day(_ id: DayID) -> ReadingDay? {
        week(id.week)?.days.first { $0.number == id.day }
    }

    /// The plan transcribed from the 34-week schedule, shipped as `reading_plan.json`.
    static let bundled: ReadingPlan = {
        do {
            return try load(from: .main)
        } catch {
            fatalError("Unable to load bundled reading plan: \(error)")
        }
    }()

    static func load(from bundle: Bundle) throws -> ReadingPlan {
        guard let url = bundle.url(forResource: "reading_plan", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> ReadingPlan {
        let dto = try JSONDecoder().decode(PlanDTO.self, from: data)
        let weeks = dto.weeks.map { week in
            ReadingWeek(
                number: week.number,
                summary: week.summary,
                days: week.days.map { day in
                    ReadingDay(week: week.number, number: day.number, reading: day.reading, passages: day.passages)
                }
            )
        }
        return ReadingPlan(title: dto.title, subtitle: dto.subtitle, weeks: weeks)
    }
}

private struct PlanDTO: Decodable {
    struct Week: Decodable {
        let number: Int
        let summary: String
        let days: [Day]
    }

    struct Day: Decodable {
        let number: Int
        let reading: String
        let passages: [Passage]
    }

    let title: String
    let subtitle: String
    let weeks: [Week]
}
