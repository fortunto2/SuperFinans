//
//  CashFlowService.swift
//  SuperFinans
//
//  Central aggregator for the Rich Dad / Cashflow model.
//  Assets vs Liabilities, Income Statement, Balance Sheet, Freedom Ratio.
//

import CoreData
import Foundation

@MainActor
final class CashFlowService: ObservableObject {

    static let shared = CashFlowService()

    private let persistence: PersistenceController
    private let accountService: AccountService
    private let transactionService: TransactionService

    private init(
        persistence: PersistenceController = .shared,
        accountService: AccountService = .shared,
        transactionService: TransactionService = .shared
    ) {
        self.persistence = persistence
        self.accountService = accountService
        self.transactionService = transactionService
    }

    var baseCurrency: String {
        UserDefaults.standard.string(forKey: "superfinans.currency_code") ?? "USD"
    }

    // MARK: - Assets & Liabilities

    func fetchAssets() -> [AccountEntity] {
        accountService.fetchAccounts().filter { !$0.accountType.isLiability }
    }

    func fetchLiabilities() -> [AccountEntity] {
        accountService.fetchAccounts().filter { $0.accountType.isLiability }
    }

    func totalAssets() -> Int64 {
        fetchAssets().reduce(Int64(0)) { $0 + $1.balanceMinorUnits }
    }

    func totalLiabilities() -> Int64 {
        fetchLiabilities().reduce(Int64(0)) { $0 + abs($1.balanceMinorUnits) }
    }

    func netWorth() -> Int64 {
        let accounts = accountService.fetchAccounts()
        return accounts.reduce(Int64(0)) { $0 + $1.netWorthContribution }
    }

    // MARK: - Grouped Balance Sheet

    struct AccountGroupSection: Identifiable {
        let id = UUID()
        let groupName: String
        let iconName: String
        let accounts: [AccountEntity]
        let subtotal: Int64
    }

    func assetsGrouped() -> [AccountGroupSection] {
        let assets = fetchAssets()
        let groups: [(name: String, icon: String, types: [AccountType])] = [
            ("Cash & Savings", "banknote.fill", [.checking, .savings, .cash]),
            ("Investments", "chart.line.uptrend.xyaxis", [.investment]),
            ("Crypto", "bitcoinsign.circle.fill", [.crypto]),
            ("Business", "briefcase.fill", [.company]),
        ]

        return groups.compactMap { group in
            let matching = assets.filter { group.types.contains($0.accountType) }
            guard !matching.isEmpty else { return nil }
            let subtotal = matching.reduce(Int64(0)) { $0 + $1.balanceMinorUnits }
            return AccountGroupSection(
                groupName: group.name,
                iconName: group.icon,
                accounts: matching,
                subtotal: subtotal
            )
        }
    }

    func liabilitiesGrouped() -> [AccountGroupSection] {
        let liabilities = fetchLiabilities()
        let groups: [(name: String, icon: String, types: [AccountType])] = [
            ("Credit Cards", "creditcard.fill", [.credit]),
            ("Loans", "doc.text.fill", [.loan]),
        ]

        return groups.compactMap { group in
            let matching = liabilities.filter { group.types.contains($0.accountType) }
            guard !matching.isEmpty else { return nil }
            let subtotal = matching.reduce(Int64(0)) { $0 + abs($1.balanceMinorUnits) }
            return AccountGroupSection(
                groupName: group.name,
                iconName: group.icon,
                accounts: matching,
                subtotal: subtotal
            )
        }
    }

    // MARK: - Income

    /// Total monthly passive income from all assets (balance * rate / 12)
    func totalMonthlyPassiveIncome() -> Int64 {
        fetchAssets().reduce(Int64(0)) { $0 + $1.monthlyPassiveIncome.minorUnits }
    }

    /// Active income from transactions for a given month
    func activeIncome(for month: Date) -> Int64 {
        transactionService.totalIncome(for: month)
    }

    // MARK: - Expenses

    /// Total expenses from transactions for a given month
    func totalExpenses(for month: Date) -> Int64 {
        transactionService.totalSpending(for: month)
    }

    /// Expenses grouped by ExpenseGroup
    func expensesByGroup(for month: Date) -> [(group: ExpenseGroup, total: Int64)] {
        let transactions = transactionService.fetchTransactions(for: month).filter { $0.isExpense }
        var groupTotals: [ExpenseGroup: Int64] = [:]

        for tx in transactions {
            let category = tx.category ?? .other
            let group = category.expenseGroup
            groupTotals[group, default: 0] += abs(tx.amountMinorUnits)
        }

        return ExpenseGroup.allCases.compactMap { group in
            guard let total = groupTotals[group], total > 0 else { return nil }
            return (group: group, total: total)
        }
    }

    // MARK: - Freedom Metrics

    /// Freedom ratio: passive income / monthly expenses
    func freedomRatio(for month: Date) -> Decimal {
        let passive = Decimal(totalMonthlyPassiveIncome())
        let expenses = Decimal(totalExpenses(for: month))
        guard expenses > 0 else { return passive > 0 ? 1 : 0 }
        return passive / expenses
    }

    /// Months to financial freedom
    func monthsToFreedom(for month: Date) -> Int? {
        let expenses = totalExpenses(for: month)
        let income = activeIncome(for: month) + totalMonthlyPassiveIncome()
        let surplus = income - expenses

        let investedAssets = fetchAssets()
            .filter { $0.accountType == .investment || $0.accountType == .crypto || $0.accountType == .company }
            .reduce(Int64(0)) { $0 + $1.balanceMinorUnits }

        return FinancialCalculator.shared.monthsToFreedom(
            currentInvestedAssets: investedAssets,
            monthlyExpenses: expenses,
            monthlySurplus: surplus,
            averageAnnualReturn: weightedAverageReturn()
        )
    }

    /// Weighted average return across all rate-bearing assets
    func weightedAverageReturn() -> Decimal {
        let assets = fetchAssets().filter { $0.effectiveAnnualRate > 0 }
        let totalBalance = assets.reduce(Decimal(0)) { $0 + Decimal($1.balanceMinorUnits) }
        guard totalBalance > 0 else { return Decimal(string: "0.08") ?? Decimal(8) / Decimal(100) }

        let weightedSum = assets.reduce(Decimal(0)) {
            $0 + Decimal($1.balanceMinorUnits) * $1.effectiveAnnualRate
        }
        return weightedSum / totalBalance
    }
}
