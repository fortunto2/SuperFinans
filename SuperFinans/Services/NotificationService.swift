//
//  NotificationService.swift
//  SuperFinans
//
//  Local notification helpers for goal milestones and reminders.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("NotificationService: Permission error: \(error)")
            return false
        }
    }

    func scheduleMilestoneNotification(goalName: String, milestone: GoalMilestone) {
        let content = UNMutableNotificationContent()
        content.title = "\(milestone.emoji) Milestone Reached!"
        content.body = "Your goal \"\(goalName)\" hit \(milestone.label). Keep going!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "milestone_\(goalName)_\(milestone.rawValue)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Monthly check-in

    static let monthlyCheckInID = "freedom_monthly_checkin"

    /// One notification a month, on the 1st at 10:00, and nothing else.
    ///
    /// Daily "log your spending" nagging is why people delete finance apps.
    /// A month is also the natural cadence here: nothing a person does in a
    /// week moves a date that sits a decade out.
    func scheduleMonthlyCheckIn() {
        let content = UNMutableNotificationContent()
        content.title = "A month went by"
        content.body = "Did anything change? Update the numbers and see where your freedom year lands."
        content.sound = .default

        var when = DateComponents()
        when.day = 1
        when.hour = 10

        let request = UNNotificationRequest(
            identifier: Self.monthlyCheckInID,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancelMonthlyCheckIn() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.monthlyCheckInID])
    }

    var isMonthlyCheckInScheduled: Bool {
        get async {
            let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
            return pending.contains { $0.identifier == Self.monthlyCheckInID }
        }
    }
}
