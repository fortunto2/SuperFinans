//
//  CategoryDefinition.swift
//  SuperFinans
//
//  20 predefined spending categories with SF Symbols.
//

import SwiftUI

enum CategoryDefinition: String, CaseIterable, Codable, Identifiable, Sendable {

    // Essentials
    case housing = "housing"
    case groceries = "groceries"
    case utilities = "utilities"
    case transportation = "transportation"
    case healthcare = "healthcare"
    case insurance = "insurance"

    // Lifestyle
    case dining = "dining"
    case entertainment = "entertainment"
    case shopping = "shopping"
    case clothing = "clothing"
    case personalCare = "personal_care"

    // Financial
    case income = "income"
    case savings = "savings"
    case investments = "investments"
    case debt = "debt"

    // Family & Education
    case education = "education"
    case childcare = "childcare"
    case pets = "pets"

    // Other
    case travel = "travel"
    case other = "other"

    // MARK: - Identifiable

    var id: String { rawValue }

    // MARK: - Display

    var displayName: String {
        switch self {
        case .housing: return "Housing"
        case .groceries: return "Groceries"
        case .utilities: return "Utilities"
        case .transportation: return "Transportation"
        case .healthcare: return "Healthcare"
        case .insurance: return "Insurance"
        case .dining: return "Dining Out"
        case .entertainment: return "Entertainment"
        case .shopping: return "Shopping"
        case .clothing: return "Clothing"
        case .personalCare: return "Personal Care"
        case .income: return "Income"
        case .savings: return "Savings"
        case .investments: return "Investments"
        case .debt: return "Debt Payment"
        case .education: return "Education"
        case .childcare: return "Childcare"
        case .pets: return "Pets"
        case .travel: return "Travel"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .housing: return "house.fill"
        case .groceries: return "cart.fill"
        case .utilities: return "bolt.fill"
        case .transportation: return "car.fill"
        case .healthcare: return "heart.fill"
        case .insurance: return "shield.fill"
        case .dining: return "fork.knife"
        case .entertainment: return "tv.fill"
        case .shopping: return "bag.fill"
        case .clothing: return "tshirt.fill"
        case .personalCare: return "sparkles"
        case .income: return "banknote.fill"
        case .savings: return "dollarsign.circle.fill"
        case .investments: return "chart.line.uptrend.xyaxis"
        case .debt: return "creditcard.fill"
        case .education: return "book.fill"
        case .childcare: return "figure.and.child.holdinghands"
        case .pets: return "pawprint.fill"
        case .travel: return "airplane"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .housing: return .blue
        case .groceries: return .green
        case .utilities: return .yellow
        case .transportation: return .orange
        case .healthcare: return .red
        case .insurance: return .purple
        case .dining: return .pink
        case .entertainment: return .indigo
        case .shopping: return .mint
        case .clothing: return .teal
        case .personalCare: return .cyan
        case .income: return Color.goalMint
        case .savings: return Color.goalMint
        case .investments: return .green
        case .debt: return .red
        case .education: return .blue
        case .childcare: return .orange
        case .pets: return .brown
        case .travel: return .cyan
        case .other: return .gray
        }
    }

    /// Whether this category represents income (positive amounts)
    var isIncome: Bool {
        self == .income
    }

    /// Categories grouped for the picker
    static var expenseCategories: [CategoryDefinition] {
        allCases.filter { $0 != .income }
    }
}
