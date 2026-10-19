import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var store: ProgressStore
    @State private var hideCompleted = false

    private var visibleWeeks: [ReadingWeek] {
        hideCompleted ? store.plan.weeks.filter { !store.isComplete($0) } : store.plan.weeks
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List(visibleWeeks) { week in
                    NavigationLink(value: week) {
                        WeekRow(week: week)
                    }
                    .id(week.number)
                }
                .navigationTitle("Reading Plan")
                .navigationDestination(for: ReadingWeek.self) { week in
                    WeekDetailView(week: week)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Current") {
                            if let week = store.nextDay?.week {
                                withAnimation { proxy.scrollTo(week, anchor: .top) }
                            }
                        }
                        .disabled(store.nextDay == nil)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Toggle(isOn: $hideCompleted) {
                            Label("Hide completed", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        .toggleStyle(.button)
                    }
                }
            }
        }
    }
}

struct WeekRow: View {
    @EnvironmentObject private var store: ProgressStore
    let week: ReadingWeek

    var body: some View {
        let complete = store.isComplete(week)
        HStack(spacing: 14) {
            ZStack {
                ProgressRing(fraction: store.weekFraction(week), lineWidth: 4)
                if complete {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(Color.accentColor)
                } else {
                    Text("\(week.number)")
                        .font(.caption.bold())
                        .monospacedDigit()
                }
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Week \(week.number)")
                        .font(.headline)
                    if store.nextDay?.week == week.number {
                        Text("CURRENT")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Text(week.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct WeekDetailView: View {
    @EnvironmentObject private var store: ProgressStore
    let week: ReadingWeek

    var body: some View {
        List {
            Section("Weekly assignment") {
                Text(week.summary)
                ProgressView(value: store.weekFraction(week)) {
                    Text("\(store.completedDayCount(week)) of \(week.days.count) days complete")
                        .font(.subheadline)
                }
            }

            Section("Days") {
                ForEach(week.days) { day in
                    NavigationLink {
                        DayDetailView(day: day)
                    } label: {
                        DayRow(day: day)
                    }
                    .swipeActions(edge: .leading) {
                        let complete = store.isComplete(day)
                        Button {
                            store.setDay(day, complete: !complete)
                        } label: {
                            Label(complete ? "Unread" : "Read", systemImage: complete ? "arrow.uturn.backward" : "checkmark")
                        }
                        .tint(complete ? Color.gray : Color.green)
                    }
                }
            }
        }
        .navigationTitle("Week \(week.number)")
        .toolbar {
            Button(store.isComplete(week) ? "Mark all unread" : "Mark all read") {
                let complete = !store.isComplete(week)
                withAnimation {
                    for day in week.days { store.setDay(day, complete: complete) }
                }
            }
        }
    }
}

struct DayRow: View {
    @EnvironmentObject private var store: ProgressStore
    let day: ReadingDay

    var body: some View {
        let complete = store.isComplete(day)
        let done = store.completedPassageCount(day)
        HStack(spacing: 12) {
            Image(systemName: complete ? "checkmark.circle.fill" : done > 0 ? "circle.lefthalf.filled" : "circle")
                .font(.title3)
                .foregroundStyle(complete || done > 0 ? Color.accentColor : Color.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Day \(day.number)")
                    .font(.headline)
                Text(day.reading)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !store.note(for: day).isEmpty {
                    Label("Has notes", systemImage: "note.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    PlanView()
        .environmentObject(ProgressStore.preview)
}
