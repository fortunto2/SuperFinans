//
//  RecurringRuleService.swift
//  SuperFinans
//
//  CRUD operations for recurring transaction rules
//  and auto-generation of due transactions.
//

import CoreData
import Foundation

@MainActor
final class RecurringRuleService {

    static let shared = RecurringRuleService()
    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    // MARK: - Fetch

    func fetchActiveRules() -> [RecurringRuleEntity] {
        let request = RecurringRuleEntity.fetchRequestActive()
        do {
            return try persistence.viewContext.fetch(request)
        } catch {
            print("RecurringRuleService: Failed to fetch rules: \(error)")
            return []
        }
    }

    func fetchAllRules() -> [RecurringRuleEntity] {
        let request = RecurringRuleEntity.fetchRequest() as NSFetchRequest<RecurringRuleEntity>
        request.sortDescriptors = [NSSortDescriptor(key: "nextDueDate", ascending: true)]
        do {
            return try persistence.viewContext.fetch(request)
        } catch {
            print("RecurringRuleService: Failed to fetch all rules: \(error)")
            return []
        }
    }

    // MARK: - Create

    @discardableResult
    func createRule(
        amount: Int64,
        currencyCode: String = "USD",
        categoryId: String? = nil,
        note: String? = nil,
        frequency: RecurringFrequency = .monthly,
        dayOfMonth: Int16 = 1,
        dayOfWeek: Int16 = 1,
        nextDueDate: Date,
        account: AccountEntity? = nil
    ) -> RecurringRuleEntity {
        let ctx = persistence.viewContext
        let rule = RecurringRuleEntity(context: ctx)
        rule.id = UUID()
        rule.templateAmountMinorUnits = amount
        rule.currencyCode = currencyCode
        rule.categoryId = categoryId
        rule.note = note
        rule.frequency = frequency.rawValue
        rule.dayOfMonth = dayOfMonth
        rule.dayOfWeek = dayOfWeek
        rule.nextDueDate = nextDueDate
        rule.isActive = true
        rule.account = account
        persistence.save()
        return rule
    }

    // MARK: - Update

    func updateRule(_ rule: RecurringRuleEntity) {
        persistence.save()
    }

    // MARK: - Delete

    func deleteRule(_ rule: RecurringRuleEntity) {
        persistence.viewContext.delete(rule)
        persistence.save()
    }

    // MARK: - Generate Due Transactions

    /// Generate transactions for all active rules whose nextDueDate <= today.
    /// Uses a while loop to catch up on ALL missed periods (e.g. if the app
    /// wasn't opened for 2 months, it generates all overdue transactions).
    /// Call this when the app becomes active.
    func generateDueTransactions() {
        let rules = fetchActiveRules()
        let today = Date()
        let ctx = persistence.viewContext

        for rule in rules {
            // Catch up on ALL overdue periods, not just one
            while let dueDate = rule.nextDueDate, dueDate <= today {
                // Create the transaction
                let tx = TransactionEntity(context: ctx)
                tx.id = UUID()
                tx.amountMinorUnits = rule.templateAmountMinorUnits
                tx.currencyCode = rule.currencyCode ?? "USD"
                tx.categoryId = rule.categoryId
                tx.note = rule.note
                tx.date = dueDate
                tx.isRecurring = true
                tx.recurringRuleId = rule.id
                tx.createdAt = Date()
                tx.updatedAt = Date()
                tx.account = rule.account
                tx.recurringRule = rule

                // Update account balance
                if let account = rule.account {
                    account.balanceMinorUnits += rule.templateAmountMinorUnits
                    account.updatedAt = Date()
                }

                // Advance nextDueDate
                rule.nextDueDate = nextDate(after: dueDate, frequency: rule.recurringFrequency)
            }
        }

        persistence.save()
    }

    // MARK: - Helpers

    private func nextDate(after date: Date, frequency: RecurringFrequency) -> Date {
        let calendar = Calendar.current
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}
