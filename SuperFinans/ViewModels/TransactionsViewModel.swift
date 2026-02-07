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
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(transactionService: TransactionService? = nil) {
        self.transactionService = transactionService ?? TransactionService.shared
        loadTransactions()
    }

    // MARK: - Load

    func loadTransactions() {
        transactions = transactionService.fetchTransactions(for: selectedMonth)

        let currency = transactions.first?.currencyCode ?? "USD"
        let spending = transactionService.totalSpending(for: selectedMonth)
        totalSpending = Money(minorUnits: spending, currencyCode: currency)

        let income = transactionService.totalIncome(for: selectedMonth)
        totalIncome = Money(minorUnits: income, currencyCode: currency)
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
}
