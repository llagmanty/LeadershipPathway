import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ProgressStore

    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderTime") private var reminderTime = SettingsView.defaultReminderTime
    @State private var confirmingReset = false
    @State private var notificationsDenied = false

    private static var defaultReminderTime: Double {
        let date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        return date.timeIntervalSinceReferenceDate
    }

    private var reminderDate: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSinceReferenceDate: reminderTime) },
            set: { reminderTime = $0.timeIntervalSinceReferenceDate }
        )
    }

    private var hasStartDate: Binding<Bool> {
        Binding(
            get: { store.startDate != nil },
            set: { store.setStartDate($0 ? Date() : nil) }
        )
    }

    private var startDate: Binding<Date> {
        Binding(
            get: { store.startDate ?? Date() },
            set: { store.setStartDate($0) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Track a schedule", isOn: hasStartDate)
                    if store.startDate != nil {
                        DatePicker("Start date", selection: startDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    Text("The plan has 5 reading days per week. With a start date, the app tells you whether you're on track, ahead or behind.")
                }

                Section {
                    Toggle("Daily reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: reminderDate, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    if notificationsDenied {
                        Text("Notifications are turned off for this app. Enable them in the Settings app to receive reminders.")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Reset all progress", role: .destructive) {
                        confirmingReset = true
                    }
                } footer: {
                    Text("Clears every checked passage and note. Your start date is kept.")
                }

                Section("About") {
                    LabeledContent("Plan", value: store.plan.subtitle)
                    LabeledContent("Weeks", value: "\(store.plan.weeks.count)")
                    LabeledContent("Reading days", value: "\(store.totalDays)")
                    LabeledContent("Passages", value: "\(store.plan.totalPassages)")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Reset all progress?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { store.resetProgress() }
            } message: {
                Text("This can't be undone.")
            }
            .onChange(of: reminderEnabled) { _, _ in updateReminder() }
            .onChange(of: reminderTime) { _, _ in updateReminder() }
            .onChange(of: store.nextDay?.id) { _, _ in
                if reminderEnabled { updateReminder() }
            }
        }
    }

    @MainActor
    private func updateReminder() {
        guard reminderEnabled else {
            ReminderScheduler.cancel()
            return
        }
        Task {
            let granted = await ReminderScheduler.requestAuthorization()
            notificationsDenied = !granted
            if granted {
                let next = store.nextDay.map { "\($0.title) — \($0.reading)" }
                ReminderScheduler.schedule(at: reminderDate.wrappedValue, nextReading: next)
            } else {
                reminderEnabled = false
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ProgressStore.preview)
}
