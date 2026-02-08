//
//  TransactionService.swift
//  SuperFinans
//
//  CRUD operations for transactions.
//

import CoreData
import Foundation

@MainActor
final class TransactionService: ObservableObject {

    static let shared = TransactionService()
    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    // MARK: - Fetch

    func fetchTransactions(for month: Date? = nil) -> [TransactionEntity] {
        let request: NSFetchRequest<TransactionEntity>
        if let month {
            request = TransactionEntity.fetchRequest(for: month)
        } else {
            request = TransactionEntity.fetchRequestSorted()
        }
        do {
            return try persistence.viewContext.fetch(request)
        } catch {
            print("TransactionService: Failed to fetch: \(error)")
            return []
        }
    }

    func fetchTransactions(for accountId: UUID) -> [TransactionEntity] {
        let request = TransactionEntity.fetchRequest(accountId: accountId)
        do {
            return try persistence.viewContext.fetch(request)
        } catch {
            return []
        }
    }

    // MARK: - Create

    @discardableResult
    func createTransaction(
        amount: Int64,
        currencyCode: String = "USD",
        categoryId: String? = nil,
        note: String? = nil,
        date: Date = Date(),
        account: AccountEntity? = nil,
        goal: GoalEntity? = nil
    ) -> TransactionEntity {
        let ctx = persistence.viewContext
        let tx = TransactionEntity(context: ctx)
        tx.id = UUID()
        tx.amountMinorUnits = amount
        tx.currencyCode = currencyCode
        tx.categoryId = categoryId
        tx.note = note
        tx.date = date
        tx.isRecurring = false
        tx.createdAt = Date()
        tx.updatedAt = Date()
        tx.account = account
        tx.goal = goal

        // Update account balance
        if let account {
            account.balanceMinorUnits += amount
            account.updatedAt = Date()
        }

        persistence.save()

        FeatureDiscoveryFlags.shared.trackTransaction()

        return tx
    }

    // MARK: - Update

    func updateTransaction(_ transaction: TransactionEntity) {
        transaction.updatedAt = Date()
        persistence.save()
    }

    // MARK: - Delete

    func deleteTransaction(_ transaction: TransactionEntity) {
        // Reverse account balance change
        if let account = transaction.account {
            account.balanceMinorUnits -= transaction.amountMinorUnits
            account.updatedAt = Date()
        }

        // Reverse goal deposit
        if let goal = transaction.goal {
            goal.currentAmountMinorUnits -= transaction.amountMinorUnits
            goal.updatedAt = Date()
        }

        persistence.viewContext.delete(transaction)
        persistence.save()
    }

    // MARK: - Aggregation

    /// Spending by category for a given month
    func spendingByCategory(for month: Date) -> [(category: CategoryDefinition, total: Int64)] {
        let transactions = fetchTransactions(for: month).filter { $0.isExpense }
        var categoryTotals: [String: Int64] = [:]

        for tx in transactions {
            let key = tx.categoryId ?? "other"
            categoryTotals[key, default: 0] += abs(tx.amountMinorUnits)
        }

        return categoryTotals.compactMap { key, total in
            guard let category = CategoryDefinition(rawValue: key) else { return nil }
            return (category: category, total: total)
        }.sorted { $0.total > $1.total }
    }

    /// Total spending for a month
    func totalSpending(for month: Date) -> Int64 {
        fetchTransactions(for: month)
            .filter { $0.isExpense }
            .reduce(0) { $0 + abs($1.amountMinorUnits) }
    }

    /// Total income for a month
    func totalIncome(for month: Date) -> Int64 {
        fetchTransactions(for: month)
            .filter { $0.isIncome }
            .reduce(0) { $0 + $1.amountMinorUnits }
    }
}
