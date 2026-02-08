//
//  BalanceSheetView.swift
//  SuperFinans
//
//  Balance Sheet — Assets grouped (Cash & Savings, Investments, Crypto, Business),
//  Liabilities grouped (Credit Cards, Loans), Net Worth.
//

import SwiftUI

struct BalanceSheetView: View {

    @StateObject private var viewModel = BalanceSheetViewModel()

    var body: some View {
        NavigationStack {
            List {
                // Net Worth Header
                Section {
                    netWorthHeader
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))

                // Assets
                ForEach(viewModel.assetGroups) { group in
                    Section {
                        ForEach(group.accounts, id: \.id) { account in
                            NavigationLink(value: account) {
                                assetRow(account)
                            }
                        }
                    } header: {
                        sectionHeader(
                            title: group.groupName,
                            icon: group.iconName,
                            subtotal: Money(minorUnits: group.subtotal, currencyCode: viewModel.baseCurrency),
                            color: .incomeGreen
                        )
                    }
                }

                // Liabilities
                ForEach(viewModel.liabilityGroups) { group in
                    Section {
                        ForEach(group.accounts, id: \.id) { account in
                            NavigationLink(value: account) {
                                liabilityRow(account)
                            }
                        }
                    } header: {
                        sectionHeader(
                            title: group.groupName,
                            icon: group.iconName,
                            subtotal: Money(minorUnits: group.subtotal, currencyCode: viewModel.baseCurrency),
                            color: .expenseRed
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Balance Sheet")
            .onAppear { viewModel.loadData() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        NavigationLink(destination: AccountsManagementView()) {
                            Image(systemName: "gearshape")
                        }
                        Button {
                            viewModel.showCreateAccount = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateAccount) {
                viewModel.loadData()
            } content: {
                AccountFormView(mode: .create)
            }
            .navigationDestination(for: AccountEntity.self) { account in
                AccountDetailView(account: account)
            }
        }
    }

    // MARK: - Net Worth Header

    private var netWorthHeader: some View {
        VStack(spacing: 12) {
            Text("Net Worth")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(viewModel.netWorth.formatted)
                .font(.system(.title, design: .rounded, weight: .bold))

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("Assets")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalAssets.formatted)
                        .font(.caption.bold())
                        .foregroundColor(.incomeGreen)
                }
                Text("−")
                    .foregroundStyle(.secondary)
                VStack(spacing: 2) {
                    Text("Liabilities")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalLiabilities.formatted)
                        .font(.caption.bold())
                        .foregroundColor(.expenseRed)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String, subtotal: Money, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.subheadline.bold())
            Spacer()
            Text(subtotal.formatted)
                .font(.caption.bold())
                .foregroundColor(color)
        }
    }

    // MARK: - Asset Row

    private func assetRow(_ account: AccountEntity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: account.accountType.iconName)
                .font(.title3)
                .foregroundColor(Color(hexString: account.colorHex ?? "42A5F5"))
                .frame(width: 36, height: 36)
                .background(Color(hexString: account.colorHex ?? "42A5F5").opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayName)
                    .font(.subheadline.bold())
                HStack(spacing: 4) {
                    if let rateDesc = account.rateDescription {
                        Text(rateDesc)
                            .font(.caption)
                            .foregroundColor(.goalMint)
                    }
                    if account.monthlyPassiveIncome.minorUnits > 0 {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("\(account.monthlyPassiveIncome.formatted)/mo")
                            .font(.caption)
                            .foregroundColor(.incomeGreen)
                    }
                }
            }

            Spacer()

            Text(account.balance.formatted)
                .font(.subheadline.bold())
        }
    }

    // MARK: - Liability Row

    private func liabilityRow(_ account: AccountEntity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: account.accountType.iconName)
                .font(.title3)
                .foregroundColor(.expenseRed)
                .frame(width: 36, height: 36)
                .background(Color.expenseRed.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayName)
                    .font(.subheadline.bold())
                HStack(spacing: 4) {
                    if let rateDesc = account.rateDescription {
                        Text(rateDesc)
                            .font(.caption)
                            .foregroundColor(.expenseRed)
                    }
                    if account.monthlyCost.minorUnits > 0 {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("\(account.monthlyCost.formatted)/mo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Text(Money(minorUnits: abs(account.balanceMinorUnits), currencyCode: account.currency).formatted)
                .font(.subheadline.bold())
                .foregroundColor(.expenseRed)
        }
    }
}

#Preview {
    BalanceSheetView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
