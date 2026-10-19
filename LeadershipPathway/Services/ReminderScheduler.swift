import Foundation
import UserNotifications

/// Schedules a single repeating local notification reminding the user to read.
enum ReminderScheduler {
    private static let identifier = "daily-reading-reminder"

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func schedule(at time: Date, nextReading: String?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Time for today's reading"
        content.body = nextReading.map { "Up next: \($0)" } ?? "Keep walking your Leadership Pathway."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger), withCompletionHandler: nil)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
