//
//  CashFlowView.swift
//  SuperFinans
//
//  Income Statement view — Active/Passive income, Expenses by group
//  (Needs/Wants/Debt Service), Net Cash Flow, Transactions list.
//

import SwiftUI

struct CashFlowView: View {

    @StateObject private var viewModel = CashFlowViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.transactions.isEmpty && viewModel.passiveIncome.isZero {
                    EmptyStateView(
                        icon: "arrow.left.arrow.right",
                        title: "No Cash Flow Data",
                        subtitle: "Add transactions to see your income statement and cash flow analysis.",
                        buttonTitle: "Add Transaction"
                    ) {
                        viewModel.showAddTransaction = true
                    }
                } else {
                    cashFlowContent
                }
            }
            .navigationTitle("Cash Flow")
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
                    Label(viewModel.totalExpenses.formatted, systemImage: "arrow.down")
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

    // MARK: - Content

    private var cashFlowContent: some View {
        List {
            // Income Section
            Section {
                HStack {
                    Label("Active (Salary/Business)", systemImage: "person.fill")
                        .font(.subheadline)
                    Spacer()
                    Text(viewModel.activeIncome.formatted)
                        .font(.subheadline.bold())
                        .foregroundColor(.incomeGreen)
                }

                HStack {
                    Label("Passive (Investments)", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.subheadline)
                    Spacer()
                    Text(viewModel.passiveIncome.formatted)
                        .font(.subheadline.bold())
                        .foregroundColor(.goalMint)
                }
            } header: {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.incomeGreen)
                    Text("Income")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(viewModel.totalIncome.formatted)
                        .font(.caption.bold())
                        .foregroundColor(.incomeGreen)
                }
            }

            // Expenses Section
            if !viewModel.expensesByGroup.isEmpty {
                Section {
                    ForEach(viewModel.expensesByGroup, id: \.group) { item in
                        HStack {
                            Label(item.group.displayName, systemImage: item.group.iconName)
                                .font(.subheadline)
                                .foregroundColor(item.group.color)
                            Spacer()
                            Text(item.total.formatted)
                                .font(.subheadline.bold())
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.expenseRed)
                        Text("Expenses")
                            .font(.subheadline.bold())
                        Spacer()
                        Text(viewModel.totalExpenses.formatted)
                            .font(.caption.bold())
                            .foregroundColor(.expenseRed)
                    }
                }
            }

            // Net Cash Flow
            Section {
                HStack {
                    Text("Net Cash Flow")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.netCashFlow.formatted)
                        .font(.headline)
                        .foregroundColor(viewModel.netCashFlow.isNegative ? .expenseRed : .incomeGreen)
                }
            }

            // Transactions
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

#Preview {
    CashFlowView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
