import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject private var store: ProgressStore
    let day: ReadingDay

    @State private var noteText = ""
    @FocusState private var noteFocused: Bool

    var body: some View {
        Form {
            Section {
                ForEach(day.passages.indices, id: \.self) { index in
                    PassageRow(day: day, index: index)
                }
            } header: {
                Text("Readings")
            } footer: {
                if let date = store.completionDate(of: day) {
                    Text("Completed \(date.formatted(date: .abbreviated, time: .shortened))")
                }
            }

            Section("Notes & reflections") {
                TextField("What stood out to you? How will you apply it?", text: $noteText, axis: .vertical)
                    .lineLimit(4...12)
                    .focused($noteFocused)
            }

            Section {
                let complete = store.isComplete(day)
                Button(complete ? "Mark day as unread" : "Mark day complete") {
                    withAnimation(.snappy) { store.setDay(day, complete: !complete) }
                }
                .foregroundStyle(complete ? Color.red : Color.accentColor)
            }

            if let week = store.plan.week(day.week) {
                Section("This week") {
                    Text(week.summary)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(day.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { noteFocused = false }
            }
        }
        .onAppear { noteText = store.note(for: day) }
        .onChange(of: noteText) { _, newValue in
            store.setNote(newValue, for: day)
        }
    }
}

#Preview {
    NavigationStack {
        DayDetailView(day: ReadingPlan.bundled.allDays[0])
    }
    .environmentObject(ProgressStore.preview)
}
