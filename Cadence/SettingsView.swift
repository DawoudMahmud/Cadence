import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var remindersEnabled: Bool = ReminderService.isEnabled
    @State private var time: Date = {
        var comps = ReminderService.time
        comps.year = 2000; comps.month = 1; comps.day = 1
        return Calendar.current.date(from: comps) ?? .now
    }()
    @State private var permissionDenied = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    Toggle("Daily check-in", isOn: $remindersEnabled)
                        .onChange(of: remindersEnabled, initial: false) { _, newValue in
                            Task { await handleToggle(newValue) }
                        }

                    DatePicker("Time",
                               selection: $time,
                               displayedComponents: .hourAndMinute)
                        .disabled(!remindersEnabled)
                        .onChange(of: time, initial: false) { _, _ in
                            guard remindersEnabled else { return }
                            Task { await reschedule() }
                        }

                    if permissionDenied {
                        Text("Notifications are off in Settings — enable them for Cadence to receive reminders.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Text("Cadence v1")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func handleToggle(_ on: Bool) async {
        if on {
            let granted = await ReminderService.requestAuthorization()
            if !granted {
                permissionDenied = true
                remindersEnabled = false
                return
            }
            permissionDenied = false
            await reschedule()
        } else {
            ReminderService.cancel()
        }
    }

    private func reschedule() async {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        await ReminderService.schedule(hour: comps.hour ?? 20, minute: comps.minute ?? 0)
    }
}

#Preview {
    SettingsView()
}
