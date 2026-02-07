//
//  GoalEntity+CoreData.swift
//  SuperFinans
//
//  Core Data managed object class for financial goals.
//

import CoreData
import Foundation

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

    var interestRate: Decimal {
        annualInterestRate?.decimalValue ?? Decimal(0)
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
