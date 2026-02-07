//
//  DashboardView.swift
//  SuperFinans
//
//  Main dashboard — Freedom Ratio ring, Net Worth (Assets - Liabilities),
//  Monthly Snapshot, Time to Freedom, Passive Income Breakdown.
//

import SwiftUI
import Charts

struct DashboardView: View {

    @StateObject private var viewModel = DashboardViewModel()
    @Binding var deepLinkGoalId: UUID?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    // Freedom Ratio
                    freedomRatioCard

                    // Net Worth
                    netWorthCard

                    // Monthly Snapshot
                    monthlySnapshotCard

                    // Time to Freedom
                    timeToFreedomCard

                    // Passive Income Breakdown
                    if !viewModel.passiveIncomeBreakdown.isEmpty {
                        passiveIncomeCard
                    }

                    // Milestones
                    if !viewModel.milestones.isEmpty {
                        milestonesSection
                    }

                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            viewModel.showAddTransaction = true
                        } label: {
                            Label("Add Transaction", systemImage: "plus.circle")
                        }
                        Button {
                            viewModel.showCreateAccount = true
                        } label: {
                            Label("Add Account", systemImage: "building.columns")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddTransaction) {
                viewModel.loadAll()
            } content: {
                AddTransactionView()
            }
            .sheet(isPresented: $viewModel.showCreateAccount) {
                viewModel.loadAll()
            } content: {
                AccountFormView(mode: .create)
            }
            .navigationDestination(for: GoalEntity.self) { goal in
                GoalDetailView(goal: goal)
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

    // MARK: - Freedom Ratio

    private var freedomRatioCard: some View {
        VStack(spacing: 12) {
            Text("Freedom Ratio")
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressRingView(
                progress: min(viewModel.freedomRatio.doubleValue, 1.0),
                lineWidth: 14,
                size: 140,
                color: freedomColor
            )

            Text(freedomLabel)
                .font(.caption)
                .foregroundColor(freedomColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var freedomColor: Color {
        let ratio = viewModel.freedomRatio.doubleValue
        if ratio >= 1.0 { return Color(hex: 0xFFD700) } // gold
        if ratio >= 0.75 { return .incomeGreen }
        if ratio >= 0.5 { return .yellow }
        if ratio >= 0.25 { return .orange }
        return .expenseRed
    }

    private var freedomLabel: String {
        let ratio = viewModel.freedomRatio.doubleValue
        if ratio >= 1.0 { return "Financially Free!" }
        if ratio >= 0.75 { return "Almost there!" }
        if ratio >= 0.5 { return "Halfway to freedom" }
        if ratio >= 0.25 { return "Building momentum" }
        return "Starting the journey"
    }

    // MARK: - Net Worth

    private var netWorthCard: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Worth")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.netWorth.formatted)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                }
                Spacer()
                Image(systemName: "scale.3d")
                    .font(.title2)
                    .foregroundColor(.goalMint)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Monthly Snapshot

    private var monthlySnapshotCard: some View {
        HStack(spacing: 0) {
            snapshotItem(
                title: "Income",
                amount: viewModel.monthlyIncome,
                color: .incomeGreen,
                icon: "arrow.up"
            )
            Divider().frame(height: 40)
            snapshotItem(
                title: "Expenses",
                amount: viewModel.monthlyExpenses,
                color: .expenseRed,
                icon: "arrow.down"
            )
            Divider().frame(height: 40)
            snapshotItem(
                title: "Surplus",
                amount: viewModel.monthlySurplus,
                color: viewModel.monthlySurplus.isNegative ? .expenseRed : .incomeGreen,
                icon: viewModel.monthlySurplus.isNegative ? "exclamationmark.triangle" : "checkmark.circle"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func snapshotItem(title: String, amount: Money, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(amount.formatted)
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Time to Freedom

    private var timeToFreedomCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Time to Freedom")
                    .font(.headline)
                Spacer()
            }

            if let months = viewModel.monthsToFreedom {
                let years = months / 12
                let remainingMonths = months % 12
                HStack {
                    if years > 0 {
                        Text("\(years)")
                            .font(.system(.title, design: .rounded, weight: .bold))
                        Text(years == 1 ? "year" : "years")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if remainingMonths > 0 {
                        Text("\(remainingMonths)")
                            .font(.system(.title, design: .rounded, weight: .bold))
                        Text(remainingMonths == 1 ? "month" : "months")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Mini chart: passive income vs expenses
                if viewModel.freedomProjection.count > 1 {
                    Chart {
                        ForEach(viewModel.freedomProjection) { point in
                            LineMark(
                                x: .value("Month", point.date),
                                y: .value("Passive Income", point.passiveIncome.doubleValue / 100)
                            )
                            .foregroundStyle(Color.incomeGreen)
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Month", point.date),
                                y: .value("Expenses", point.expenses.doubleValue / 100)
                            )
                            .foregroundStyle(Color.expenseRed)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(dash: [5, 3]))
                        }
                    }
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .year, count: max(1, (viewModel.monthsToFreedom ?? 120) / 12 / 5))) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.year())
                        }
                    }
                    .frame(height: 100)
                }
            } else {
                Text("Keep building your investment assets to calculate your path to freedom.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Passive Income Breakdown

    private var passiveIncomeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    .foregroundColor(.goalMint)
                Text("Passive Income")
                    .font(.headline)
                Spacer()
                Text(viewModel.monthlyPassiveIncome.formatted)
                    .font(.caption.bold())
                    .foregroundColor(.goalMint)
            }

            ForEach(viewModel.passiveIncomeBreakdown, id: \.account.id) { item in
                HStack {
                    Image(systemName: item.account.accountType.iconName)
                        .font(.caption)
                        .foregroundColor(Color(hexString: item.account.colorHex ?? "42A5F5"))
                        .frame(width: 24)
                    Text(item.account.displayName)
                        .font(.subheadline)
                    Spacer()
                    Text(item.income.formatted)
                        .font(.subheadline.bold())
                        .foregroundColor(.incomeGreen)
                    Text("/mo")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Milestones

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.goalMint)
                Text("Milestones")
                    .font(.headline)
                Spacer()
            }

            ForEach(viewModel.milestones, id: \.id) { goal in
                NavigationLink(value: goal) {
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

                        Text("\(Int(goal.progressPercentage * 100))%")
                            .font(.caption.bold())
                            .foregroundColor(Color(hexString: goal.colorHex ?? "4ECDC4"))
                            .frame(width: 40, alignment: .trailing)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.showAddTransaction = true
            } label: {
                Label("Add Transaction", systemImage: "plus.circle.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient.mintGradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                viewModel.showCreateAccount = true
            } label: {
                Label("Add Account", systemImage: "building.columns")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

#Preview {
    DashboardView(deepLinkGoalId: .constant(nil))
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
