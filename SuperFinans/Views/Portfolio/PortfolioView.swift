//
//  PortfolioView.swift
//  SuperFinans
//
//  Main dashboard — Net Worth, accounts by group (Family / Business),
//  and milestones (financial goals).
//

import SwiftUI

struct PortfolioView: View {

    @StateObject private var viewModel = PortfolioViewModel()
    @Binding var deepLinkGoalId: UUID?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                // Net Worth Header
                Section {
                    netWorthCard
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))

                // Family Accounts
                if !viewModel.personalAccounts.isEmpty {
                    Section {
                        ForEach(viewModel.personalAccounts, id: \.id) { account in
                            NavigationLink(value: account) {
                                accountRow(account)
                            }
                        }
                    } header: {
                        groupHeader(
                            title: "Family",
                            icon: "house.fill",
                            total: viewModel.personalTotal
                        )
                    }
                }

                // Business Accounts
                if !viewModel.businessAccounts.isEmpty {
                    Section {
                        ForEach(viewModel.businessAccounts, id: \.id) { account in
                            NavigationLink(value: account) {
                                accountRow(account)
                            }
                        }
                    } header: {
                        groupHeader(
                            title: "Business",
                            icon: "briefcase.fill",
                            total: viewModel.businessTotal
                        )
                    }
                }

                // Milestones
                if !viewModel.milestones.isEmpty {
                    Section {
                        ForEach(viewModel.milestones, id: \.id) { goal in
                            NavigationLink(value: goal) {
                                milestoneRow(goal)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    viewModel.quickDepositGoal = goal
                                    viewModel.quickDepositAmount = ""
                                } label: {
                                    Label("Deposit", systemImage: "plus.circle.fill")
                                }
                                .tint(.goalMint)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    if let index = viewModel.milestones.firstIndex(where: { $0.id == goal.id }) {
                                        viewModel.deleteGoal(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "flag.fill")
                                .foregroundColor(.goalMint)
                            Text("Milestones")
                                .font(.subheadline.bold())
                            Spacer()
                            Text("\(Int(viewModel.milestonesProgress * 100))%")
                                .font(.caption.bold())
                                .foregroundColor(.goalMint)
                        }
                    }
                }

                // Empty state
                if viewModel.allAccounts.isEmpty {
                    Section {
                        emptyState
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            viewModel.showCreateAccount = true
                        } label: {
                            Label("New Account", systemImage: "building.columns")
                        }
                        Button {
                            viewModel.requestCreateGoal()
                        } label: {
                            Label("New Milestone", systemImage: "flag")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateAccount) {
                viewModel.loadAll()
            } content: {
                AccountFormView(mode: .create)
            }
            .sheet(isPresented: $viewModel.showCreateGoal) {
                viewModel.loadAll()
            } content: {
                CreateGoalView()
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                SuperFinansPaywallView()
            }
            .sheet(item: $viewModel.quickDepositGoal) { goal in
                quickDepositSheet(for: goal)
            }
            .overlay {
                if let milestone = viewModel.celebratingMilestone {
                    MilestoneCelebrationView(
                        milestone: milestone,
                        goalName: viewModel.celebratingGoalName ?? "Goal"
                    ) {
                        viewModel.dismissMilestone()
                    }
                }
            }
            .navigationDestination(for: GoalEntity.self) { goal in
                GoalDetailView(goal: goal)
            }
            .navigationDestination(for: AccountEntity.self) { account in
                AccountDetailView(account: account)
            }
            .onChange(of: deepLinkGoalId) { newId in
                if let id = newId,
                   let goal = viewModel.milestones.first(where: { $0.id == id }) {
                    navigationPath.append(goal)
                    deepLinkGoalId = nil
                }
            }
        }
    }

    // MARK: - Net Worth Card

    private var netWorthCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Worth")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.netWorthMoney.formatted)
                        .font(.system(.title, design: .rounded, weight: .bold))
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.goalMint)
            }

            // Group breakdown
            if !viewModel.personalAccounts.isEmpty || !viewModel.businessAccounts.isEmpty {
                HStack(spacing: 16) {
                    if !viewModel.personalAccounts.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "house.fill")
                                .font(.caption2)
                                .foregroundColor(.goalBlue)
                            Text(viewModel.personalTotal.formatted)
                                .font(.caption.bold())
                        }
                    }
                    if !viewModel.businessAccounts.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "briefcase.fill")
                                .font(.caption2)
                                .foregroundColor(.goalPurple)
                            Text(viewModel.businessTotal.formatted)
                                .font(.caption.bold())
                        }
                    }
                    Spacer()
                    Text("\(viewModel.allAccounts.count) accounts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Group Header

    private func groupHeader(title: String, icon: String, total: Money) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(title == "Family" ? .goalBlue : .goalPurple)
            Text(title)
                .font(.subheadline.bold())
            Spacer()
            Text(total.formatted)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Account Row

    private func accountRow(_ account: AccountEntity) -> some View {
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
                    Text(account.accountType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let rateDesc = account.rateDescription {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(rateDesc)
                            .font(.caption)
                            .foregroundColor(.goalMint)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(account.balance.formatted)
                    .font(.subheadline.bold())
                Text(account.currency)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Milestone Row

    private func milestoneRow(_ goal: GoalEntity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: goal.iconName ?? "flag.fill")
                .font(.body)
                .foregroundColor(Color(hexString: goal.colorHex ?? "4ECDC4"))
                .frame(width: 32, height: 32)
                .background(Color(hexString: goal.colorHex ?? "4ECDC4").opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(goal.displayName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                ProgressView(value: goal.progressPercentage)
                    .tint(Color(hexString: goal.colorHex ?? "4ECDC4"))
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(goal.progressPercentage * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(Color(hexString: goal.colorHex ?? "4ECDC4"))
                Text(goal.currentAmount.formatted)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 70, alignment: .trailing)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse)

            VStack(spacing: 8) {
                Text("Build Your Portfolio")
                    .font(.title3.bold())
                Text("Add your bank accounts, brokerages, crypto wallets, and company accounts to track your net worth.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.showCreateAccount = true
            } label: {
                Text("Add First Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient.mintGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Quick Deposit Sheet

    private func quickDepositSheet(for goal: GoalEntity) -> some View {
        NavigationStack {
            Form {
                MoneyTextField(
                    label: "Amount",
                    value: $viewModel.quickDepositAmount,
                    currencyCode: goal.currency
                )
            }
            .navigationTitle("Deposit to \(goal.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.quickDepositGoal = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Deposit") { viewModel.addQuickDeposit() }
                        .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Account Detail (placeholder — navigates to account info)

struct AccountDetailView: View {
    let account: AccountEntity

    var body: some View {
        List {
            Section("Account Info") {
                HStack {
                    Text("Type")
                    Spacer()
                    Text(account.accountType.displayName)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Currency")
                    Spacer()
                    Text(account.currency)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Balance")
                    Spacer()
                    Text(account.balance.formatted)
                        .font(.headline)
                }
                if let rateDesc = account.rateDescription {
                    HStack {
                        Text("Rate")
                        Spacer()
                        Text(rateDesc)
                            .foregroundColor(.goalMint)
                    }
                }
                if let ticker = account.benchmarkTicker, !ticker.isEmpty {
                    HStack {
                        Text("Benchmark")
                        Spacer()
                        Text(ticker)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Group") {
                HStack {
                    Image(systemName: account.accountGroup.icon)
                    Text(account.accountGroup.displayName)
                }
            }

            // Linked goals
            let linkedGoals = (account.goals?.allObjects as? [GoalEntity]) ?? []
            if !linkedGoals.isEmpty {
                Section("Linked Milestones") {
                    ForEach(linkedGoals, id: \.id) { goal in
                        HStack {
                            Image(systemName: goal.iconName ?? "flag.fill")
                                .foregroundColor(Color(hexString: goal.colorHex ?? "4ECDC4"))
                            Text(goal.displayName)
                            Spacer()
                            Text("\(Int(goal.progressPercentage * 100))%")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Recent transactions
            let recentTx = account.transactionsArray
                .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
                .prefix(10)
            if !recentTx.isEmpty {
                Section("Recent Transactions") {
                    ForEach(Array(recentTx), id: \.id) { tx in
                        HStack {
                            Text(tx.note ?? tx.categoryId ?? "Transaction")
                                .font(.subheadline)
                            Spacer()
                            Text(Money(minorUnits: tx.amountMinorUnits, currencyCode: account.currency).formatted)
                                .font(.subheadline.bold())
                                .foregroundColor(tx.amountMinorUnits >= 0 ? .incomeGreen : .expenseRed)
                        }
                    }
                }
            }
        }
        .navigationTitle(account.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PortfolioView(deepLinkGoalId: .constant(nil))
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
