//
//  RecurringRuleEntity+CoreData.swift
//  SuperFinans
//
//  Core Data managed object class for recurring transaction rules.
//

import CoreData
import Foundation

@objc(RecurringRuleEntity)
public class RecurringRuleEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var templateAmountMinorUnits: Int64
    @NSManaged public var currencyCode: String?
    @NSManaged public var categoryId: String?
    @NSManaged public var note: String?
    @NSManaged public var frequency: String?
    @NSManaged public var dayOfMonth: Int16
    @NSManaged public var dayOfWeek: Int16
    @NSManaged public var nextDueDate: Date?
    @NSManaged public var isActive: Bool

    // Relationships
    @NSManaged public var account: AccountEntity?
    @NSManaged public var transactions: NSSet?
}

// MARK: - Convenience

extension RecurringRuleEntity {

    var recurringFrequency: RecurringFrequency {
        RecurringFrequency(rawValue: frequency ?? "monthly") ?? .monthly
    }

    var templateAmount: Money {
        Money(minorUnits: templateAmountMinorUnits, currencyCode: currencyCode ?? "USD")
    }
}

// MARK: - Fetch Requests

extension RecurringRuleEntity {

    static func fetchRequest() -> NSFetchRequest<RecurringRuleEntity> {
        NSFetchRequest<RecurringRuleEntity>(entityName: "RecurringRuleEntity")
    }

    static func fetchRequestActive() -> NSFetchRequest<RecurringRuleEntity> {
        let request = NSFetchRequest<RecurringRuleEntity>(entityName: "RecurringRuleEntity")
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "nextDueDate", ascending: true)]
        return request
    }
}

// MARK: - Recurring Frequency

enum RecurringFrequency: String, CaseIterable, Codable, Sendable {
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}
