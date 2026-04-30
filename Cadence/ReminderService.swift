import Foundation
import UserNotifications

enum ReminderService {

    static let dailyReminderID = "cadence.daily-log"
    private static let enabledKey = "remindersEnabled"
    private static let hourKey    = "remindersHour"
    private static let minuteKey  = "remindersMinute"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var hour: Int {
        get { UserDefaults.standard.object(forKey: hourKey) as? Int ?? 20 }
        set { UserDefaults.standard.set(newValue, forKey: hourKey) }
    }

    static var minute: Int {
        get { UserDefaults.standard.object(forKey: minuteKey) as? Int ?? 0 }
        set { UserDefaults.standard.set(newValue, forKey: minuteKey) }
    }

    static var time: DateComponents {
        DateComponents(hour: hour, minute: minute)
    }

    /// Asks for notification permission. Returns true if granted.
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Schedule (or replace) the recurring daily reminder.
    static func schedule(hour: Int, minute: Int) async {
        self.hour = hour
        self.minute = minute
        self.isEnabled = true

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])

        let content = UNMutableNotificationContent()
        content.title = "Cadence"
        content.body = "Quick check-in — log today's followers and post stats."
        content.sound = .default

        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReminderID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
        isEnabled = false
    }
}
