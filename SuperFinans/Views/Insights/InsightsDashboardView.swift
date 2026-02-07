//
//  InsightsDashboardView.swift
//  SuperFinans
//
//  Main view for the Insights tab with spending charts.
//

import SwiftUI
import Charts

struct InsightsDashboardView: View {

    @StateObject private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Monthly summary
                    monthlySummaryCard

                    // Spending by category
                    spendingByCategoryChart

                    // Monthly trend
                    monthlyTrendChart

                    // AI Insight teaser
                    if !PremiumManager.shared.isPremium {
                        aiInsightTeaser
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
            .onAppear { viewModel.refresh() }
        }
    }

    // MARK: - Monthly Summary

    private var monthlySummaryCard: some View {
        VStack(spacing: 8) {
            Text("This Month")
                .font(.headline)
            Text(viewModel.totalSpendingThisMonth.formatted)
                .font(.system(size: 36, weight: .bold, design: .rounded))
            Text("Total Spending")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Spending by Category

    private var spendingByCategoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category")
                .font(.headline)

            if viewModel.spendingByCategory.isEmpty {
                Text("No spending data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                Chart {
                    ForEach(viewModel.spendingByCategory.prefix(8), id: \.category) { item in
                        BarMark(
                            x: .value("Amount", Double(item.total) / 100.0),
                            y: .value("Category", item.category.displayName)
                        )
                        .foregroundStyle(item.category.color)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        if let amount = value.as(Double.self) {
                            AxisValueLabel {
                                Text("$\(Int(amount))")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(min(viewModel.spendingByCategory.count, 8)) * 40)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Monthly Trend

    private var monthlyTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Trend")
                .font(.headline)

            if viewModel.monthlyTrend.isEmpty {
                Text("Not enough data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            } else {
                Chart {
                    ForEach(viewModel.monthlyTrend) { month in
                        BarMark(
                            x: .value("Month", month.label),
                            y: .value("Spending", Double(month.spending) / 100.0)
                        )
                        .foregroundStyle(Color.expenseRed.opacity(0.7))
                    }
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - AI Insight Teaser

    private var aiInsightTeaser: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.goalMint)
                Text("AI Insights")
                    .font(.headline)
                Spacer()
                PremiumBadgeView()
            }

            Text("Get personalized spending analysis, savings tips, and anomaly detection powered by on-device AI.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(0.7)
    }
}

#Preview {
    InsightsDashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
