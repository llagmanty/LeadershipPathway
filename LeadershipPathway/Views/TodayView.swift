import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: ProgressStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    if let day = store.nextDay {
                        nextReadingCard(day)
                    } else {
                        finishedCard
                    }
                    if let week = store.nextDay.flatMap({ store.plan.week($0.week) }) {
                        weekCard(week)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 20) {
            ZStack {
                ProgressRing(fraction: store.overallFraction)
                Text(store.overallFraction, format: .percent.precision(.fractionLength(0)))
                    .font(.title3.bold())
                    .monospacedDigit()
            }
            .frame(width: 96, height: 96)

            VStack(alignment: .leading, spacing: 6) {
                Text(store.plan.title)
                    .font(.headline)
                Text("\(store.completedDays) of \(store.totalDays) days read")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label("\(store.currentStreak)-day streak", systemImage: "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(store.currentStreak > 0 ? Color.orange : Color.secondary)
                ScheduleBadge(status: store.scheduleStatus)
            }
        }
        .card()
    }

    private func nextReadingCard(_ day: ReadingDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("UP NEXT")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(day.title)
                        .font(.title2.bold())
                }
                Spacer()
                NavigationLink {
                    DayDetailView(day: day)
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                }
                .accessibilityLabel("Open day details and notes")
            }

            ForEach(day.passages.indices, id: \.self) { index in
                PassageRow(day: day, index: index)
                if index < day.passages.count - 1 { Divider() }
            }

            Button {
                withAnimation(.snappy) { store.setDay(day, complete: true) }
            } label: {
                Label("Mark day complete", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .card()
    }

    private var finishedCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "rosette")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text("Pathway complete!")
                .font(.title2.bold())
            Text("You've finished all \(store.plan.weeks.count) weeks of the plan.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private func weekCard(_ week: ReadingWeek) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Week \(week.number)")
                    .font(.headline)
                Spacer()
                Text("\(store.completedDayCount(week))/\(week.days.count) days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(week.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(week.days) { day in
                    NavigationLink {
                        DayDetailView(day: day)
                    } label: {
                        DayChip(day: day)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .card()
    }
}

struct DayChip: View {
    @EnvironmentObject private var store: ProgressStore
    let day: ReadingDay

    var body: some View {
        let complete = store.isComplete(day)
        let isNext = store.nextDay?.id == day.id
        VStack(spacing: 4) {
            Text("Day")
                .font(.caption2)
            Text("\(day.number)")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .foregroundStyle(complete ? Color.white : Color.primary)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(complete ? Color.accentColor : Color(.tertiarySystemFill))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: isNext ? 2 : 0)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Day \(day.number), \(complete ? "complete" : "not complete")")
    }
}

struct ScheduleBadge: View {
    let status: ScheduleStatus

    var body: some View {
        switch status {
        case .notStarted:
            EmptyView()
        case .onTrack:
            Label("On track", systemImage: "checkmark.seal.fill")
                .font(.subheadline)
                .foregroundStyle(.green)
        case .ahead(let days):
            Label("\(days) day\(days == 1 ? "" : "s") ahead", systemImage: "hare.fill")
                .font(.subheadline)
                .foregroundStyle(.green)
        case .behind(let days):
            Label("\(days) day\(days == 1 ? "" : "s") behind", systemImage: "tortoise.fill")
                .font(.subheadline)
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(ProgressStore.preview)
}
