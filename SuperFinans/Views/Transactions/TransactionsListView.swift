//
//  TransactionsListView.swift
//  SuperFinans
//
//  Main view for the Transactions tab with date-grouped list.
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
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

    // MARK: - Transactions List

    private var transactionsList: some View {
        List {
            ForEach(viewModel.groupedTransactions, id: \.date) { group in
                Section {
                    ForEach(group.transactions, id: \.id) { transaction in
                        TransactionRow(transaction: transaction)
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

            // Amount
            Text(transaction.amount.formatted)
                .font(.subheadline.bold())
                .foregroundColor(transaction.isIncome ? .incomeGreen : .expenseRed)
        }
    }
}

#Preview {
    TransactionsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
