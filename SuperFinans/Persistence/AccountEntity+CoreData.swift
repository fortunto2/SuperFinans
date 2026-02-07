//
//  AccountEntity+CoreData.swift
//  SuperFinans
//
//  Core Data managed object class for accounts.
//

import CoreData
import Foundation

@objc(AccountEntity)
public class AccountEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var type: String?
    @NSManaged public var currencyCode: String?
    @NSManaged public var balanceMinorUnits: Int64
    @NSManaged public var iconName: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var sortOrder: Int32
    @NSManaged public var isArchived: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastModifiedBy: String?

    // Relationships
    @NSManaged public var transactions: NSSet?
    @NSManaged public var goals: NSSet?
    @NSManaged public var recurringRules: NSSet?
}

// MARK: - Convenience

extension AccountEntity {

    var displayName: String { name ?? "Account" }
    var currency: String { currencyCode ?? "USD" }
    var balance: Money { Money(minorUnits: balanceMinorUnits, currencyCode: currency) }

    var accountType: AccountType {
        AccountType(rawValue: type ?? "checking") ?? .checking
    }

    var transactionsArray: [TransactionEntity] {
        (transactions?.allObjects as? [TransactionEntity]) ?? []
    }
}

// MARK: - Fetch Requests

extension AccountEntity {

    static func fetchRequest() -> NSFetchRequest<AccountEntity> {
        NSFetchRequest<AccountEntity>(entityName: "AccountEntity")
    }

    static func fetchRequestSorted() -> NSFetchRequest<AccountEntity> {
        let request = NSFetchRequest<AccountEntity>(entityName: "AccountEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        request.predicate = NSPredicate(format: "isArchived == NO")
        return request
    }

    static func fetchRequest(id: UUID) -> NSFetchRequest<AccountEntity> {
        let request = NSFetchRequest<AccountEntity>(entityName: "AccountEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return request
    }
}

// MARK: - Account Type

enum AccountType: String, CaseIterable, Codable, Sendable {
    case checking = "checking"
    case savings = "savings"
    case credit = "credit"
    case cash = "cash"

    var displayName: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .credit: return "Credit Card"
        case .cash: return "Cash"
        }
    }

    var iconName: String {
        switch self {
        case .checking: return "building.columns.fill"
        case .savings: return "banknote.fill"
        case .credit: return "creditcard.fill"
        case .cash: return "dollarsign.circle.fill"
        }
    }
}
