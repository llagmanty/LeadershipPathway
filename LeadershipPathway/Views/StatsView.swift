import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: ProgressStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    overview
                    statsGrid
                    trackProgress
                    heatmap
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
        }
    }

    private var overview: some View {
        VStack(spacing: 12) {
            ZStack {
                ProgressRing(fraction: store.overallFraction, lineWidth: 16)
                VStack {
                    Text(store.overallFraction, format: .percent.precision(.fractionLength(0)))
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                    Text("of the pathway")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 160, height: 160)
            ScheduleBadge(status: store.scheduleStatus)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(store.completedDays)/\(store.totalDays)", label: "Days read", symbol: "calendar")
            StatTile(value: "\(store.completedWeeks)/\(store.plan.weeks.count)", label: "Weeks finished", symbol: "flag.checkered")
            StatTile(value: "\(store.currentStreak)", label: "Day streak", symbol: "flame.fill")
            StatTile(value: "\(store.snapshot.completedPassages.count)/\(store.plan.totalPassages)", label: "Passages", symbol: "text.book.closed.fill")
        }
    }

    private var trackProgress: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tracks")
                .font(.headline)
            ForEach(PassageCategory.allCases) { category in
                let fraction = store.fraction(for: category)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(category.title, systemImage: category.symbol)
                            .foregroundStyle(category.color)
                        Spacer()
                        Text(fraction, format: .percent.precision(.fractionLength(0)))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    ProgressView(value: fraction)
                        .tint(category.color)
                }
            }
        }
        .card()
    }

    private var heatmap: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("All \(store.plan.weeks.count) weeks")
                .font(.headline)
            Text("Each row is a week; each square is a day.")
                .font(.caption)
                .foregroundStyle(.secondary)
            let columns = [GridItem(.fixed(28), alignment: .leading)] + Array(repeating: GridItem(.flexible(), spacing: 4), count: 5)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(store.plan.weeks) { week in
                    Text("\(week.number)")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    ForEach(week.days) { day in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color.accentColor.opacity(0.15 + 0.85 * store.dayFraction(day)))
                            .frame(height: 14)
                            .accessibilityLabel("\(day.title), \(store.isComplete(day) ? "complete" : "not complete")")
                    }
                }
            }
        }
        .card()
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }
}

#Preview {
    StatsView()
        .environmentObject(ProgressStore.preview)
}
