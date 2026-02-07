//
//  GoalProjection.swift
//  SuperFinans
//
//  Data point for goal projection charts.
//

import Foundation

/// A single point on the goal projection curve
struct GoalProjectionPoint: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let projectedAmount: Decimal
    let contributionOnly: Decimal
}

/// Milestone levels for goal celebration
enum GoalMilestone: Int, CaseIterable, Comparable {
    case quarter = 25
    case half = 50
    case threeQuarters = 75
    case complete = 100

    var label: String {
        switch self {
        case .quarter: return "25%"
        case .half: return "50%"
        case .threeQuarters: return "75%"
        case .complete: return "100%"
        }
    }

    var emoji: String {
        switch self {
        case .quarter: return "🌱"
        case .half: return "🌿"
        case .threeQuarters: return "🌳"
        case .complete: return "🎉"
        }
    }

    static func < (lhs: GoalMilestone, rhs: GoalMilestone) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Returns the highest milestone reached for a given percentage
    static func reached(for percentage: Double) -> GoalMilestone? {
        allCases.last { Double($0.rawValue) <= percentage }
    }
}

/// Compounding frequency options
enum CompoundingFrequency: String, CaseIterable, Codable, Sendable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case semiAnnually = "semi_annually"
    case annually = "annually"

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnually: return "Semi-Annually"
        case .annually: return "Annually"
        }
    }

    var periodsPerYear: Int {
        switch self {
        case .monthly: return 12
        case .quarterly: return 4
        case .semiAnnually: return 2
        case .annually: return 1
        }
    }
}
