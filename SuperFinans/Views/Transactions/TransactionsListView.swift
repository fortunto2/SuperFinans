//
//  TransactionsListView.swift
//  SuperFinans
//
//  Main view for the Transactions tab with date-grouped list,
//  running balance, and recurring rules access.
//

import SwiftUI

struct TransactionsListView: View {

    @StateObject private var viewModel = TransactionsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.transactions.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle.portrait",
                        title: "No Transactions",
                        subtitle: "Start tracking your spending to understand where your money goes.",
                        buttonTitle: "Add Transaction"
                    ) {
                        viewModel.showAddTransaction = true
                    }
                } else {
                    transactionsList
                }
            }
            .navigationTitle("Transactions")
            .onAppear { viewModel.refresh() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        NavigationLink(destination: RecurringRulesView()) {
                            Image(systemName: "repeat.circle")
                        }
                        Button {
                            viewModel.showAddTransaction = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                monthSelector
            }
            .sheet(isPresented: $viewModel.showAddTransaction) {
                viewModel.refresh()
            } content: {
                AddTransactionView()
            }
        }
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button {
                viewModel.changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.selectedMonth.monthYearFormatted)
                    .font(.headline)
                HStack(spacing: 12) {
                    Label(viewModel.totalIncome.formatted, systemImage: "arrow.up")
                        .font(.caption)
                        .foregroundColor(.incomeGreen)
                    Label(viewModel.totalSpending.formatted, systemImage: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.expenseRed)
                }
            }

            Spacer()

            Button {
                viewModel.changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(viewModel.selectedMonth.isCurrentMonth)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Cash Flow Summary

    private var cashFlowSummary: some View {
        DisclosureGroup("Cash Flow Summary") {
            VStack(spacing: 8) {
                // Income
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.incomeGreen)
                    Text("Income")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(viewModel.totalIncome.formatted)
                        .font(.subheadline.bold())
                        .foregroundColor(.incomeGreen)
                }
                HStack {
                    Text("  Active (Salary/Business)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.activeIncome.formatted)
                        .font(.caption)
                }
                HStack {
                    Text("  Passive (Investments)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.passiveIncome.formatted)
                        .font(.caption)
                        .foregroundColor(.goalMint)
                }

                Divider()

                // Expenses
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.expenseRed)
                    Text("Expenses")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(viewModel.totalSpending.formatted)
                        .font(.subheadline.bold())
                        .foregroundColor(.expenseRed)
                }
                ForEach(viewModel.expensesByGroup, id: \.group) { item in
                    HStack {
                        Text("  \(item.group.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(item.total.formatted)
                            .font(.caption)
                    }
                }

                Divider()

                // Net Cash Flow
                HStack {
                    Text("Net Cash Flow")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(viewModel.netCashFlow.formatted)
                        .font(.subheadline.bold())
                        .foregroundColor(viewModel.netCashFlow.isNegative ? .expenseRed : .incomeGreen)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Transactions List

    private var transactionsList: some View {
        List {
            Section {
                cashFlowSummary
            }

            ForEach(viewModel.groupedTransactions, id: \.date) { group in
                Section {
                    ForEach(group.transactions, id: \.id) { transaction in
                        TransactionRow(
                            transaction: transaction,
                            runningBalance: viewModel.runningBalances[transaction.id ?? UUID()]
                        )
                    }
                    .onDelete { offsets in
                        viewModel.deleteTransaction(at: offsets, in: group.transactions)
                    }
                } header: {
                    Text(group.displayDate)
                        .font(.subheadline.bold())
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: TransactionEntity
    var runningBalance: Money?

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            if let category = transaction.category {
                Image(systemName: category.iconName)
                    .font(.body)
                    .frame(width: 36, height: 36)
                    .background(category.color.opacity(0.15))
                    .clipShape(Circle())
            } else {
                Image(systemName: "circle.fill")
                    .font(.body)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category?.displayName ?? "Uncategorized")
                    .font(.subheadline)
                if !transaction.displayNote.isEmpty {
                    Text(transaction.displayNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Amount + Running Balance
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amount.formatted)
                    .font(.subheadline.bold())
                    .foregroundColor(transaction.isIncome ? .incomeGreen : .expenseRed)

                if let balance = runningBalance {
                    Text(balance.formatted)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

#Preview {
    TransactionsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
