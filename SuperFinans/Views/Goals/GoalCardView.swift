//
//  GoalCardView.swift
//  SuperFinans
//
//  Card showing a goal with progress ring in the goals list.
//

import SwiftUI

struct GoalCardView: View {

    let goal: GoalEntity

    private var goalColor: Color {
        Color(hexString: goal.colorHex ?? "4ECDC4")
    }

    var body: some View {
        HStack(spacing: 16) {
            // Progress ring
            CompactProgressRing(progress: goal.progressPercentage, color: goalColor)

            // Goal info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: goal.iconName ?? "star.fill")
                        .font(.subheadline)
                        .foregroundColor(goalColor)
                    Text(goal.displayName)
                        .font(.headline)
                        .lineLimit(1)
                }

                Text("\(goal.currentAmount.formatted) of \(goal.targetAmount.formatted)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Target date
            if let targetDate = goal.targetDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(targetDate.monthYearFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let months = goal.monthsRemaining, months > 0 {
                        Text("\(months) mo")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
