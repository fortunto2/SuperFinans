//
//  TransactionEntity+CoreData.swift
//  SuperFinans
//
//  Core Data managed object class for transactions.
//

import CoreData
import Foundation

@objc(TransactionEntity)
public class TransactionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var amountMinorUnits: Int64
    @NSManaged public var currencyCode: String?
    @NSManaged public var categoryId: String?
    @NSManaged public var note: String?
    @NSManaged public var date: Date?
    @NSManaged public var isRecurring: Bool
    @NSManaged public var recurringRuleId: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastModifiedBy: String?

    // Relationships
    @NSManaged public var account: AccountEntity?
    @NSManaged public var goal: GoalEntity?
    @NSManaged public var recurringRule: RecurringRuleEntity?
}

// MARK: - Convenience

extension TransactionEntity {

    var amount: Money {
        Money(minorUnits: amountMinorUnits, currencyCode: currencyCode ?? "USD")
    }

    var isExpense: Bool { amountMinorUnits < 0 }
    var isIncome: Bool { amountMinorUnits > 0 }

    var category: CategoryDefinition? {
        guard let categoryId else { return nil }
        return CategoryDefinition(rawValue: categoryId)
    }

    var transactionDate: Date { date ?? Date() }

    var displayNote: String { note ?? "" }
}

// MARK: - Fetch Requests

extension TransactionEntity {

    static func fetchRequest() -> NSFetchRequest<TransactionEntity> {
        NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
    }

    static func fetchRequestSorted() -> NSFetchRequest<TransactionEntity> {
        let request = NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }

    static func fetchRequest(for month: Date) -> NSFetchRequest<TransactionEntity> {
        let request = NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
        let start = month.startOfMonth
        let end = month.endOfMonth
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", start as CVarArg, end as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }

    static func fetchRequest(goalId: UUID) -> NSFetchRequest<TransactionEntity> {
        let request = NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
        request.predicate = NSPredicate(format: "goal.id == %@", goalId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }

    static func fetchRequest(accountId: UUID) -> NSFetchRequest<TransactionEntity> {
        let request = NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
        request.predicate = NSPredicate(format: "account.id == %@", accountId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }
}
