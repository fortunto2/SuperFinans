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

    // Group (personal / business)
    @NSManaged public var group: String?

    // Interest / returns
    @NSManaged public var annualInterestRate: NSDecimalNumber?
    @NSManaged public var expectedAnnualReturn: NSDecimalNumber?
    @NSManaged public var benchmarkTicker: String?

    // Relationships
    @NSManaged public var transactions: NSSet?
    @NSManaged public var goals: NSSet?
    @NSManaged public var recurringRules: NSSet?

    // Debt fields
    @NSManaged public var monthlyPaymentMinorUnits: Int64
    @NSManaged public var annualDebtInterestRate: NSDecimalNumber?
}

// MARK: - Convenience

extension AccountEntity {

    var displayName: String { name ?? "Account" }
    var currency: String { currencyCode ?? "USD" }
    var balance: Money { Money(minorUnits: balanceMinorUnits, currencyCode: currency) }

    var accountGroup: AccountGroup {
        AccountGroup(rawValue: group ?? "personal") ?? .personal
    }

    var accountType: AccountType {
        AccountType(rawValue: type ?? "checking") ?? .checking
    }

    /// The effective annual rate for projections.
    /// For savings: fixed `annualInterestRate`.
    /// For investment/crypto: `expectedAnnualReturn` (approximate).
    /// Falls back to 0 if nothing set.
    var effectiveAnnualRate: Decimal {
        if let rate = annualInterestRate?.decimalValue, rate > 0 {
            return rate
        }
        if let ret = expectedAnnualReturn?.decimalValue, ret > 0 {
            return ret
        }
        return 0
    }

    /// Human-readable rate description for display
    var rateDescription: String? {
        let rate = effectiveAnnualRate
        guard rate > 0 else { return nil }
        let pct = (rate * 100).rounded(scale: 1)
        switch accountType {
        case .savings:
            return "\(pct)% APY"
        case .investment:
            if let ticker = benchmarkTicker, !ticker.isEmpty {
                return "~\(pct)% (\(ticker))"
            }
            return "~\(pct)% expected"
        case .crypto:
            if let ticker = benchmarkTicker, !ticker.isEmpty {
                return "~\(pct)% (\(ticker))"
            }
            return "~\(pct)% expected"
        case .loan:
            return "\(pct)% APR"
        case .checking, .credit, .cash, .company:
            return "\(pct)%"
        }
    }

    var transactionsArray: [TransactionEntity] {
        (transactions?.allObjects as? [TransactionEntity]) ?? []
    }

    // MARK: - Asset / Liability

    var isLiability: Bool {
        accountType.isLiability
    }

    /// Monthly passive income from this asset (balance * rate / 12)
    var monthlyPassiveIncome: Money {
        guard !isLiability else { return Money.zero(currencyCode: currency) }
        let rate = effectiveAnnualRate
        guard rate > 0 else { return Money.zero(currencyCode: currency) }
        let monthly = Decimal(balanceMinorUnits) * rate / Decimal(12)
        let minorUnits = NSDecimalNumber(decimal: monthly.rounded(scale: 0)).int64Value
        return Money(minorUnits: minorUnits, currencyCode: currency)
    }

    /// Monthly cost for liabilities (stored monthly payment)
    var monthlyCost: Money {
        guard isLiability else { return Money.zero(currencyCode: currency) }
        return Money(minorUnits: monthlyPaymentMinorUnits, currencyCode: currency)
    }

    /// Net worth contribution: positive for assets, negative for liabilities
    var netWorthContribution: Int64 {
        if isLiability {
            return -abs(balanceMinorUnits)
        } else {
            return balanceMinorUnits
        }
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

// MARK: - Account Group

enum AccountGroup: String, CaseIterable, Codable, Sendable {
    case personal = "personal"
    case business = "business"

    var displayName: String {
        switch self {
        case .personal: return "Family"
        case .business: return "Business"
        }
    }

    var icon: String {
        switch self {
        case .personal: return "house.fill"
        case .business: return "briefcase.fill"
        }
    }
}

// MARK: - Account Type

enum AccountType: String, CaseIterable, Codable, Sendable {
    case checking = "checking"
    case savings = "savings"
    case investment = "investment"
    case crypto = "crypto"
    case credit = "credit"
    case cash = "cash"
    case company = "company"
    case loan = "loan"

    var displayName: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .investment: return "Investment"
        case .crypto: return "Crypto"
        case .credit: return "Credit Card"
        case .cash: return "Cash"
        case .company: return "Company"
        case .loan: return "Loan"
        }
    }

    var iconName: String {
        switch self {
        case .checking: return "building.columns.fill"
        case .savings: return "banknote.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .crypto: return "bitcoinsign.circle.fill"
        case .credit: return "creditcard.fill"
        case .cash: return "dollarsign.circle.fill"
        case .company: return "briefcase.fill"
        case .loan: return "doc.text.fill"
        }
    }

    /// Whether this account type supports interest/return rate
    var supportsRate: Bool {
        switch self {
        case .savings, .investment, .crypto, .loan: return true
        case .checking, .credit, .cash, .company: return false
        }
    }

    /// Label for the rate field
    var rateLabel: String {
        switch self {
        case .savings: return "Annual Interest Rate (APY)"
        case .investment: return "Expected Annual Return"
        case .crypto: return "Expected Annual Return"
        case .loan: return "Annual Interest Rate (APR)"
        default: return "Annual Rate"
        }
    }

    /// Placeholder hint for rate
    var ratePlaceholder: String {
        switch self {
        case .savings: return "e.g. 4.5"
        case .investment: return "e.g. 10 (S&P 500 avg)"
        case .crypto: return "e.g. 15"
        case .loan: return "e.g. 5.5"
        default: return "0.0"
        }
    }

    /// Whether this type is a liability (reduces net worth)
    var isLiability: Bool {
        self == .credit || self == .loan
    }
}
