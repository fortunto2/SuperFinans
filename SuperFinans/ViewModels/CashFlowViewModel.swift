//
//  CashFlowViewModel.swift
//  SuperFinans
//
//  ViewModel for the Cash Flow tab — Income Statement with
//  active/passive income, expenses by group, net cash flow.
//

import Foundation
import Combine

@MainActor
final class CashFlowViewModel: ObservableObject {

    // MARK: - Published

    @Published var selectedMonth: Date = Date()

    @Published var activeIncome: Money = .zero()
    @Published var passiveIncome: Money = .zero()
    @Published var totalIncome: Money = .zero()

    @Published var expensesByGroup: [(group: ExpenseGroup, total: Money)] = []
    @Published var totalExpenses: Money = .zero()

    @Published var netCashFlow: Money = .zero()

    @Published var transactions: [TransactionEntity] = []
    @Published var showAddTransaction = false

    // MARK: - Services

    private let cashFlowService: CashFlowService
    private let transactionService: TransactionService

    var baseCurrency: String {
        UserDefaults.standard.string(forKey: "superfinans.currency_code") ?? "USD"
    }

    // MARK: - Grouped Transactions

    var groupedTransactions: [(date: String, displayDate: String, transactions: [TransactionEntity])] {
        let grouped = Dictionary(grouping: transactions) { $0.transactionDate.dateGroupKey }
        return grouped.keys.sorted(by: >).map { key in
            let txs = grouped[key] ?? []
            let displayDate = txs.first?.transactionDate.relativeFormatted ?? key
            return (date: key, displayDate: displayDate, transactions: txs)
        }
    }

    // MARK: - Init

    init(
        cashFlowService: CashFlowService? = nil,
        transactionService: TransactionService? = nil
    ) {
        self.cashFlowService = cashFlowService ?? CashFlowService.shared
        self.transactionService = transactionService ?? TransactionService.shared
        loadData()
    }

    // MARK: - Load

    func loadData() {
        let currency = baseCurrency
        let month = selectedMonth

        // Income
        let active = cashFlowService.activeIncome(for: month)
        let passive = cashFlowService.totalMonthlyPassiveIncome()
        activeIncome = Money(minorUnits: active, currencyCode: currency)
        passiveIncome = Money(minorUnits: passive, currencyCode: currency)
        totalIncome = Money(minorUnits: active + passive, currencyCode: currency)

        // Expenses
        let expGroups = cashFlowService.expensesByGroup(for: month)
        expensesByGroup = expGroups.map { (group: $0.group, total: Money(minorUnits: $0.total, currencyCode: currency)) }
        let totalExp = cashFlowService.totalExpenses(for: month)
        totalExpenses = Money(minorUnits: totalExp, currencyCode: currency)

        // Net cash flow
        netCashFlow = Money(minorUnits: (active + passive) - totalExp, currencyCode: currency)

        // Transactions
        transactions = transactionService.fetchTransactions(for: month)
    }

    func changeMonth(by offset: Int) {
        selectedMonth = selectedMonth.addingMonths(offset)
        loadData()
    }

    func refresh() {
        loadData()
    }

    func deleteTransaction(at offsets: IndexSet, in group: [TransactionEntity]) {
        for index in offsets {
            transactionService.deleteTransaction(group[index])
        }
        loadData()
    }
}
