//
//  GoalCardView.swift
//  SuperFinans
//
//  Redesigned card showing a goal with progress bar, status badge,
//  and key metrics in a VStack layout.
//

import SwiftUI

struct GoalCardView: View {

    let goal: GoalEntity

    private var goalColor: Color {
        Color(hexString: goal.colorHex ?? "4ECDC4")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top: Icon + Name + Status Badge
            HStack(spacing: 8) {
                Image(systemName: goal.iconName ?? "star.fill")
                    .font(.title3)
                    .foregroundColor(goalColor)
                    .frame(width: 32, height: 32)
                    .background(goalColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(goal.displayName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                statusBadge
            }

            // Middle: Progress bar + percentage
            HStack(spacing: 10) {
                ProgressView(value: goal.progressPercentage)
                    .tint(goalColor)

                Text("\(Int(goal.progressPercentage * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(goalColor)
                    .frame(width: 40, alignment: .trailing)
            }

            // Bottom: Current / Target + Date
            HStack {
                Text("\(goal.currentAmount.formatted) of \(goal.targetAmount.formatted)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if let targetDate = goal.targetDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(targetDate.monthYearFormatted)
                            .font(.caption)
                        if let months = goal.monthsRemaining, months > 0 {
                            Text("(\(months) mo)")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: goalColor.opacity(0.08), radius: 8, y: 4)
        .opacity(goal.isComplete ? 0.7 : 1.0)
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        let status = goal.paceStatus
        return HStack(spacing: 3) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.label)
                .font(.caption2.bold())
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
    }
}
