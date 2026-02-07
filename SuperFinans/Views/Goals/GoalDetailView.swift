//
//  GoalDetailView.swift
//  SuperFinans
//
//  Detailed view of a single goal with projection chart,
//  what-if slider, and deposit history.
//

import SwiftUI
import Charts

struct GoalDetailView: View {

    @StateObject private var viewModel: GoalDetailViewModel

    init(goal: GoalEntity) {
        _viewModel = StateObject(wrappedValue: GoalDetailViewModel(goal: goal))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with progress ring
                headerSection

                // Projection chart
                projectionSection

                // What-if slider
                contributionSlider

                // Quick actions
                actionButtons

                // Deposit history
                depositHistory
            }
            .padding()
        }
        .navigationTitle(viewModel.goal.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showAddDeposit) {
            addDepositSheet
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ProgressRingView(
                progress: viewModel.progressPercentage,
                lineWidth: 14,
                size: 180,
                color: Color(hexString: viewModel.goal.colorHex ?? "4ECDC4")
            )

            VStack(spacing: 4) {
                Text(viewModel.goal.currentAmount.formatted)
                    .font(.title.bold())
                Text("of \(viewModel.goal.targetAmount.formatted)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let targetDate = viewModel.goal.targetDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("Target: \(targetDate.mediumFormatted)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            // Required monthly
            if viewModel.requiredMonthly.minorUnits > 0 {
                HStack {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.goalMint)
                    Text("Save \(viewModel.requiredMonthly.formatted)/mo to stay on track")
                        .font(.subheadline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.goalMint.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Projection Chart

    private var projectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Projection")
                .font(.headline)

            if !viewModel.projectionPoints.isEmpty {
                Chart {
                    ForEach(viewModel.projectionPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.projectedAmount.doubleValue)
                        )
                        .foregroundStyle(Color.goalMint)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Without Interest", point.contributionOnly.doubleValue)
                        )
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    }

                    // Target line
                    RuleMark(y: .value("Target", Double(viewModel.goal.targetAmountMinorUnits) / 100.0))
                        .foregroundStyle(Color.goalMint.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let amount = value.as(Double.self) {
                            AxisValueLabel {
                                Text(Money(minorUnits: Int64(amount), currencyCode: viewModel.goal.currency).shortFormatted)
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 200)
                .padding(.vertical, 8)
            }

            if let months = viewModel.monthsToGoalAtCurrentRate {
                Text("At current rate: reach goal in \(months) months")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Contribution Slider

    private var contributionSlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Monthly Contribution")
                    .font(.headline)
                Spacer()
                Text(Money(minorUnits: viewModel.whatIfMonthlyContribution, currencyCode: viewModel.goal.currency).formatted)
                    .font(.headline)
                    .foregroundColor(.goalMint)
            }

            Slider(
                value: $viewModel.whatIfContribution,
                in: 0...Double(viewModel.goal.targetAmountMinorUnits) / 100.0 / 6.0,
                step: 10
            )
            .tint(.goalMint)
            .onChange(of: viewModel.whatIfContribution) { _ in
                viewModel.updateProjection()
            }

            if let date = viewModel.whatIfTargetDate {
                Text("Estimated completion: \(date.mediumFormatted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.showAddDeposit = true
            } label: {
                Label("Add Deposit", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LinearGradient.mintGradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                viewModel.updateContribution()
            } label: {
                Label("Save Rate", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .font(.subheadline.bold())
    }

    // MARK: - Deposit History

    private var depositHistory: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.headline)

            if viewModel.goal.depositsArray.isEmpty {
                Text("No deposits yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(viewModel.goal.depositsArray, id: \.id) { deposit in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(deposit.displayNote.isEmpty ? "Deposit" : deposit.displayNote)
                                .font(.subheadline)
                            Text(deposit.transactionDate.mediumFormatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(deposit.amount.formatted)
                            .font(.subheadline.bold())
                            .foregroundColor(deposit.isIncome ? .incomeGreen : .expenseRed)
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Add Deposit Sheet

    private var addDepositSheet: some View {
        NavigationStack {
            Form {
                MoneyTextField(label: "Amount", value: $viewModel.depositAmount, currencyCode: viewModel.goal.currency)
                TextField("Note (optional)", text: $viewModel.depositNote)
            }
            .navigationTitle("Add Deposit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.showAddDeposit = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { viewModel.addDeposit() }
                        .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }
}
