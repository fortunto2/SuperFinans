//
//  InsightsViewModel.swift
//  SuperFinans
//
//  ViewModel for the insights/analytics tab.
//

import Foundation

@MainActor
final class InsightsViewModel: ObservableObject {

    // MARK: - Published

    @Published var spendingByCategory: [(category: CategoryDefinition, total: Int64)] = []
    @Published var monthlyTrend: [MonthlyTotal] = []
    @Published var totalSpendingThisMonth: Money = .zero()
    @Published var selectedMonth: Date = Date()

    // MARK: - Types

    struct MonthlyTotal: Identifiable {
        let id = UUID()
        let month: Date
        let spending: Int64
        let income: Int64
        var label: String { month.monthYearFormatted }
    }

    // MARK: - Services

    private let transactionService: TransactionService

    // MARK: - Init

    init(transactionService: TransactionService? = nil) {
        self.transactionService = transactionService ?? TransactionService.shared
        loadData()
    }

    // MARK: - Load

    func loadData() {
        let currency = "USD"

        // Spending by category
        spendingByCategory = transactionService.spendingByCategory(for: selectedMonth)

        // Total this month
        let total = transactionService.totalSpending(for: selectedMonth)
        totalSpendingThisMonth = Money(minorUnits: total, currencyCode: currency)

        // Monthly trend (last 6 months)
        var trend: [MonthlyTotal] = []
        for i in (0..<6).reversed() {
            let month = Date().addingMonths(-i)
            let spending = transactionService.totalSpending(for: month)
            let income = transactionService.totalIncome(for: month)
            trend.append(MonthlyTotal(month: month, spending: spending, income: income))
        }
        monthlyTrend = trend
    }

    func refresh() {
        loadData()
    }
}
