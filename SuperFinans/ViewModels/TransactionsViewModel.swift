//
//  TransactionsViewModel.swift
//  SuperFinans
//
//  ViewModel for the transactions list tab.
//

import Foundation
import Combine

@MainActor
final class TransactionsViewModel: ObservableObject {

    // MARK: - Published

    @Published var transactions: [TransactionEntity] = []
    @Published var selectedMonth: Date = Date()
    @Published var showAddTransaction = false
    @Published var totalSpending: Money = .zero()
    @Published var totalIncome: Money = .zero()
    @Published var runningBalances: [UUID: Money] = [:]

    // Cash flow summary
    @Published var activeIncome: Money = .zero()
    @Published var passiveIncome: Money = .zero()
    @Published var expensesByGroup: [(group: ExpenseGroup, total: Money)] = []
    @Published var netCashFlow: Money = .zero()

    // MARK: - Grouped

    var groupedTransactions: [(date: String, displayDate: String, transactions: [TransactionEntity])] {
        let grouped = Dictionary(grouping: transactions) { $0.transactionDate.dateGroupKey }
        return grouped.keys.sorted(by: >).map { key in
            let txs = grouped[key] ?? []
            let displayDate = txs.first?.transactionDate.relativeFormatted ?? key
            return (date: key, displayDate: displayDate, transactions: txs)
        }
    }

    // MARK: - Services

    private let transactionService: TransactionService
    private let cashFlowService: CashFlowService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        transactionService: TransactionService? = nil,
        cashFlowService: CashFlowService? = nil
    ) {
        self.transactionService = transactionService ?? TransactionService.shared
        self.cashFlowService = cashFlowService ?? CashFlowService.shared
        loadTransactions()
    }

    // MARK: - Load

    func loadTransactions() {
        transactions = transactionService.fetchTransactions(for: selectedMonth)

        let currency = UserDefaults.standard.string(forKey: "superfinans.currency_code") ?? "USD"
        let spending = transactionService.totalSpending(for: selectedMonth)
        totalSpending = Money(minorUnits: spending, currencyCode: currency)

        let income = transactionService.totalIncome(for: selectedMonth)
        totalIncome = Money(minorUnits: income, currencyCode: currency)

        // Cash flow summary
        let active = cashFlowService.activeIncome(for: selectedMonth)
        let passive = cashFlowService.totalMonthlyPassiveIncome()
        activeIncome = Money(minorUnits: active, currencyCode: currency)
        passiveIncome = Money(minorUnits: passive, currencyCode: currency)

        let expGroups = cashFlowService.expensesByGroup(for: selectedMonth)
        expensesByGroup = expGroups.map { (group: $0.group, total: Money(minorUnits: $0.total, currencyCode: currency)) }

        let totalExp = cashFlowService.totalExpenses(for: selectedMonth)
        netCashFlow = Money(minorUnits: (active + passive) - totalExp, currencyCode: currency)

        computeRunningBalances()
    }

    func changeMonth(by offset: Int) {
        selectedMonth = selectedMonth.addingMonths(offset)
        loadTransactions()
    }

    func deleteTransaction(at offsets: IndexSet, in group: [TransactionEntity]) {
        for index in offsets {
            transactionService.deleteTransaction(group[index])
        }
        loadTransactions()
    }

    func refresh() {
        loadTransactions()
    }

    // MARK: - Running Balance

    private func computeRunningBalances() {
        let currency = transactions.first?.currencyCode ?? "USD"
        // Sort oldest first for cumulative sum
        let sorted = transactions.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
        var cumulative: Int64 = 0
        var balances: [UUID: Money] = [:]

        for tx in sorted {
            cumulative += tx.amountMinorUnits
            if let id = tx.id {
                balances[id] = Money(minorUnits: cumulative, currencyCode: currency)
            }
        }

        runningBalances = balances
    }
}
