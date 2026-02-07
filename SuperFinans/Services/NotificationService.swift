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
}
