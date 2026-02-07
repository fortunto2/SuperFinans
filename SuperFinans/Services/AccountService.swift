//
//  AccountService.swift
//  SuperFinans
//
//  CRUD operations for accounts.
//

import CoreData
import Foundation

@MainActor
final class AccountService: ObservableObject {

    static let shared = AccountService()
    private let persistence: PersistenceController

    private init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    // MARK: - Fetch

    func fetchAccounts() -> [AccountEntity] {
        let request = AccountEntity.fetchRequestSorted()
        do {
            return try persistence.viewContext.fetch(request)
        } catch {
            print("AccountService: Failed to fetch: \(error)")
            return []
        }
    }

    func fetchAccount(id: UUID) -> AccountEntity? {
        let request = AccountEntity.fetchRequest(id: id)
        do {
            return try persistence.viewContext.fetch(request).first
        } catch {
            return nil
        }
    }

    func accountCount() -> Int {
        let request = AccountEntity.fetchRequestSorted()
        do {
            return try persistence.viewContext.count(for: request)
        } catch {
            return 0
        }
    }

    // MARK: - Create

    @discardableResult
    func createAccount(
        name: String,
        type: AccountType = .checking,
        currencyCode: String = "USD",
        balance: Int64 = 0,
        iconName: String? = nil,
        colorHex: String = "42A5F5",
        annualInterestRate: Decimal? = nil,
        expectedAnnualReturn: Decimal? = nil,
        benchmarkTicker: String? = nil
    ) -> AccountEntity {
        let ctx = persistence.viewContext
        let account = AccountEntity(context: ctx)
        account.id = UUID()
        account.name = name
        account.type = type.rawValue
        account.currencyCode = currencyCode
        account.balanceMinorUnits = balance
        account.iconName = iconName ?? type.iconName
        account.colorHex = colorHex
        account.sortOrder = Int32(fetchAccounts().count)
        account.isArchived = false
        account.createdAt = Date()
        account.updatedAt = Date()

        if let rate = annualInterestRate {
            account.annualInterestRate = NSDecimalNumber(decimal: rate)
        }
        if let ret = expectedAnnualReturn {
            account.expectedAnnualReturn = NSDecimalNumber(decimal: ret)
        }
        account.benchmarkTicker = benchmarkTicker

        persistence.save()
        return account
    }

    // MARK: - Update

    func updateAccount(_ account: AccountEntity) {
        account.updatedAt = Date()
        persistence.save()
    }

    // MARK: - Delete

    func deleteAccount(_ account: AccountEntity) {
        persistence.viewContext.delete(account)
        persistence.save()
    }

    // MARK: - Default Account

    /// Creates a default checking account if none exist
    func ensureDefaultAccount(currencyCode: String = "USD") {
        guard fetchAccounts().isEmpty else { return }
        createAccount(name: "Checking", type: .checking, currencyCode: currencyCode)
    }
}
