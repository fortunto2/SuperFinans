//
//  GoalEntity+CoreData.swift
//  SuperFinans
//
//  Core Data managed object class for financial goals.
//

import CoreData
import Foundation
import SwiftUI

@objc(GoalEntity)
public class GoalEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var targetAmountMinorUnits: Int64
    @NSManaged public var currentAmountMinorUnits: Int64
    @NSManaged public var currencyCode: String?
    @NSManaged public var targetDate: Date?
    @NSManaged public var annualInterestRate: NSDecimalNumber?
    @NSManaged public var compoundingFrequency: String?
    @NSManaged public var monthlyContributionMinorUnits: Int64
    @NSManaged public var iconName: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var sortOrder: Int32
    @NSManaged public var isArchived: Bool
    @NSManaged public var sharingLevel: String?
    @NSManaged public var sharedWithMemberIds: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastModifiedBy: String?

    // Relationships
    @NSManaged public var account: AccountEntity?
    @NSManaged public var deposits: NSSet?
}

// MARK: - Convenience

extension GoalEntity {

    var displayName: String { name ?? "Goal" }
    var currency: String { currencyCode ?? "USD" }

    var targetAmount: Money {
        Money(minorUnits: targetAmountMinorUnits, currencyCode: currency)
    }

    var currentAmount: Money {
        Money(minorUnits: currentAmountMinorUnits, currencyCode: currency)
    }

    var monthlyContribution: Money {
        Money(minorUnits: monthlyContributionMinorUnits, currencyCode: currency)
    }

    /// Effective interest rate: prefers account rate if linked, falls back to goal's own rate
    var interestRate: Decimal {
        if let acct = account, acct.effectiveAnnualRate > 0 {
            return acct.effectiveAnnualRate
        }
        return annualInterestRate?.decimalValue ?? Decimal(0)
    }

    var compounding: CompoundingFrequency {
        CompoundingFrequency(rawValue: compoundingFrequency ?? "monthly") ?? .monthly
    }

    var progressPercentage: Double {
        guard targetAmountMinorUnits > 0 else { return 0 }
        return min(1.0, Double(currentAmountMinorUnits) / Double(targetAmountMinorUnits))
    }

    var isComplete: Bool {
        currentAmountMinorUnits >= targetAmountMinorUnits
    }

    var monthsRemaining: Int? {
        guard let targetDate else { return nil }
        return targetDate.monthsFromNow()
    }

    var depositsArray: [TransactionEntity] {
        let set = deposits as? Set<TransactionEntity> ?? []
        return set.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    var currentMilestone: GoalMilestone? {
        GoalMilestone.reached(for: progressPercentage * 100)
    }

    var paceStatus: GoalPaceStatus {
        if isComplete { return .completed }
        guard targetAmountMinorUnits > 0 else { return .noTarget }
        guard let targetDate, targetDate > Date() else {
            // Past due or no date
            if targetDate != nil { return .behind }
            return .noTarget
        }
        // Expected progress based on time elapsed
        guard let createdAt else { return .onTrack }
        let totalDuration = targetDate.timeIntervalSince(createdAt)
        guard totalDuration > 0 else { return .onTrack }
        let elapsed = Date().timeIntervalSince(createdAt)
        let expectedProgress = elapsed / totalDuration
        let actualProgress = progressPercentage
        // Behind if actual progress is less than 80% of expected
        return actualProgress >= expectedProgress * 0.8 ? .onTrack : .behind
    }
}

// MARK: - Pace Status

enum GoalPaceStatus: String, Sendable {
    case onTrack
    case behind
    case completed
    case noTarget

    var label: String {
        switch self {
        case .onTrack: return "On Track"
        case .behind: return "Behind"
        case .completed: return "Completed"
        case .noTarget: return "No Target"
        }
    }

    var color: Color {
        switch self {
        case .onTrack: return .incomeGreen
        case .behind: return .warningAmber
        case .completed: return .goalMint
        case .noTarget: return .secondary
        }
    }

    var icon: String {
        switch self {
        case .onTrack: return "checkmark.circle.fill"
        case .behind: return "exclamationmark.triangle.fill"
        case .completed: return "star.fill"
        case .noTarget: return "minus.circle.fill"
        }
    }
}

// MARK: - Fetch Requests

extension GoalEntity {

    static func fetchRequest() -> NSFetchRequest<GoalEntity> {
        NSFetchRequest<GoalEntity>(entityName: "GoalEntity")
    }

    static func fetchRequestSorted() -> NSFetchRequest<GoalEntity> {
        let request = NSFetchRequest<GoalEntity>(entityName: "GoalEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        request.predicate = NSPredicate(format: "isArchived == NO")
        return request
    }

    static func fetchRequest(id: UUID) -> NSFetchRequest<GoalEntity> {
        let request = NSFetchRequest<GoalEntity>(entityName: "GoalEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return request
    }

    static func activeGoalCount() -> NSFetchRequest<GoalEntity> {
        let request = NSFetchRequest<GoalEntity>(entityName: "GoalEntity")
        request.predicate = NSPredicate(format: "isArchived == NO")
        return request
    }
}
