//
//  GoalService.swift
//  SuperFinans
//
//  CRUD operations for financial goals.
//

import CoreData
import Foundation

@MainActor
final class GoalService: ObservableObject {

    static let shared = GoalService()
    private let persistence: PersistenceController

    private init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    // MARK: - Fetch

    func fetchGoals() -> [GoalEntity] {
        let request = GoalEntity.fetchRequestSorted()
        do {
            return try persistence.viewContext.fetch(request)
        } catch {
            print("GoalService: Failed to fetch goals: \(error)")
            return []
        }
    }

    func fetchGoal(id: UUID) -> GoalEntity? {
        let request = GoalEntity.fetchRequest(id: id)
        do {
            return try persistence.viewContext.fetch(request).first
        } catch {
            print("GoalService: Failed to fetch goal \(id): \(error)")
            return nil
        }
    }

    func activeGoalCount() -> Int {
        let request = GoalEntity.activeGoalCount()
        do {
            return try persistence.viewContext.count(for: request)
        } catch {
            return 0
        }
    }

    // MARK: - Create

    @discardableResult
    func createGoal(
        name: String,
        targetAmount: Int64,
        currentAmount: Int64 = 0,
        currencyCode: String = "USD",
        targetDate: Date? = nil,
        annualInterestRate: Decimal = 0,
        compoundingFrequency: CompoundingFrequency = .monthly,
        monthlyContribution: Int64 = 0,
        iconName: String = "star.fill",
        colorHex: String = "4ECDC4"
    ) -> GoalEntity {
        let ctx = persistence.viewContext
        let goal = GoalEntity(context: ctx)
        goal.id = UUID()
        goal.name = name
        goal.targetAmountMinorUnits = targetAmount
        goal.currentAmountMinorUnits = currentAmount
        goal.currencyCode = currencyCode
        goal.targetDate = targetDate
        goal.annualInterestRate = NSDecimalNumber(decimal: annualInterestRate)
        goal.compoundingFrequency = compoundingFrequency.rawValue
        goal.monthlyContributionMinorUnits = monthlyContribution
        goal.iconName = iconName
        goal.colorHex = colorHex
        goal.sortOrder = Int32(fetchGoals().count)
        goal.isArchived = false
        goal.sharingLevel = "private"
        goal.createdAt = Date()
        goal.updatedAt = Date()
        persistence.save()

        NotificationCenter.default.post(name: .goalCreated, object: goal.id)
        return goal
    }

    // MARK: - Update

    func updateGoal(_ goal: GoalEntity) {
        goal.updatedAt = Date()
        persistence.save()
    }

    func addDeposit(to goal: GoalEntity, amount: Int64, note: String? = nil) {
        let ctx = persistence.viewContext
        let tx = TransactionEntity(context: ctx)
        tx.id = UUID()
        tx.amountMinorUnits = amount
        tx.currencyCode = goal.currency
        tx.note = note
        tx.date = Date()
        tx.isRecurring = false
        tx.createdAt = Date()
        tx.updatedAt = Date()
        tx.goal = goal

        goal.currentAmountMinorUnits += amount
        goal.updatedAt = Date()
        persistence.save()

        // Check milestones
        checkMilestone(for: goal)
    }

    func reorderGoals(_ goals: [GoalEntity]) {
        for (index, goal) in goals.enumerated() {
            goal.sortOrder = Int32(index)
        }
        persistence.save()
    }

    // MARK: - Delete

    func deleteGoal(_ goal: GoalEntity) {
        persistence.viewContext.delete(goal)
        persistence.save()
    }

    func archiveGoal(_ goal: GoalEntity) {
        goal.isArchived = true
        goal.updatedAt = Date()
        persistence.save()
    }

    // MARK: - Milestones

    private func checkMilestone(for goal: GoalEntity) {
        let percentage = goal.progressPercentage * 100
        if let milestone = GoalMilestone.reached(for: percentage) {
            let previousPercentage = percentage - (Double(goal.depositsArray.first?.amountMinorUnits ?? 0) / Double(goal.targetAmountMinorUnits) * 100)
            let previousMilestone = GoalMilestone.reached(for: max(0, previousPercentage))

            if milestone != previousMilestone {
                NotificationCenter.default.post(
                    name: .goalMilestoneReached,
                    object: nil,
                    userInfo: [
                        "goalId": goal.id as Any,
                        "milestone": milestone
                    ]
                )
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let goalCreated = Notification.Name("goalCreated")
    static let goalMilestoneReached = Notification.Name("goalMilestoneReached")
}
