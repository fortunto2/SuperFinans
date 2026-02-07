//
//  GoalProjectionsView.swift
//  SuperFinans
//
//  All goals on a single projection chart, each in its own color.
//

import SwiftUI
import Charts

struct GoalProjectionsView: View {

    let goals: [GoalEntity]
    private let calculator = FinancialCalculator.shared

    private var chartData: [(goal: GoalEntity, points: [GoalProjectionPoint])] {
        goals.compactMap { goal in
            let months = goal.monthsRemaining ?? 60
            guard months > 0 else { return nil }
            let points = calculator.projectionPoints(
                currentAmount: goal.currentAmountMinorUnits,
                monthlyContribution: goal.monthlyContributionMinorUnits,
                annualRate: goal.interestRate,
                months: months,
                currencyCode: goal.currency
            )
            return (goal: goal, points: points)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("All Goals Projection")
                    .font(.headline)

                if chartData.isEmpty {
                    Text("No goals with projections available.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart {
                        ForEach(chartData, id: \.goal.id) { item in
                            let color = Color(hexString: item.goal.colorHex ?? "4ECDC4")
                            ForEach(item.points) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Amount", point.projectedAmount.doubleValue),
                                    series: .value("Goal", item.goal.displayName)
                                )
                                .foregroundStyle(color)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                            }

                            // Target line
                            RuleMark(y: .value("Target", Double(item.goal.targetAmountMinorUnits) / 100.0))
                                .foregroundStyle(color.opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                                .annotation(position: .trailing, alignment: .leading) {
                                    Text(item.goal.displayName)
                                        .font(.caption2)
                                        .foregroundColor(color)
                                }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            if let amount = value.as(Double.self) {
                                let currency = goals.first?.currency ?? "USD"
                                AxisValueLabel {
                                    Text(Money(minorUnits: Int64(amount * 100), currencyCode: currency).shortFormatted)
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                        }
                    }
                    .frame(height: 300)
                    .padding(.vertical, 8)
                }

                // Legend
                ForEach(goals, id: \.id) { goal in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hexString: goal.colorHex ?? "4ECDC4"))
                            .frame(width: 10, height: 10)
                        Text(goal.displayName)
                            .font(.caption)
                        Spacer()
                        Text(goal.targetAmount.formatted)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Projections")
        .navigationBarTitleDisplayMode(.inline)
    }
}
