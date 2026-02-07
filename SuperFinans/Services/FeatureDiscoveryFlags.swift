//
//  FeatureDiscoveryFlags.swift
//  SuperFinans
//
//  Progressive disclosure flags stored in UserDefaults.
//

import Foundation

@MainActor
final class FeatureDiscoveryFlags: ObservableObject {

    static let shared = FeatureDiscoveryFlags()

    private let defaults = UserDefaults.standard
    private let prefix = "superfinans.discovery."

    private init() {}

    // MARK: - Flags

    var depositCount: Int {
        get { defaults.integer(forKey: prefix + "deposit_count") }
        set { defaults.set(newValue, forKey: prefix + "deposit_count") }
    }

    var transactionCount: Int {
        get { defaults.integer(forKey: prefix + "transaction_count") }
        set { defaults.set(newValue, forKey: prefix + "transaction_count") }
    }

    var firstGoalCreatedAt: Date? {
        get { defaults.object(forKey: prefix + "first_goal_date") as? Date }
        set { defaults.set(newValue, forKey: prefix + "first_goal_date") }
    }

    var hasShownTransactionsHint: Bool {
        get { defaults.bool(forKey: prefix + "shown_transactions_hint") }
        set { defaults.set(newValue, forKey: prefix + "shown_transactions_hint") }
    }

    var hasShownCompoundInterestHint: Bool {
        get { defaults.bool(forKey: prefix + "shown_compound_hint") }
        set { defaults.set(newValue, forKey: prefix + "shown_compound_hint") }
    }

    // MARK: - Computed

    /// Whether to show the "Track spending" hint (after 3+ deposits)
    var shouldShowTransactionsHint: Bool {
        depositCount >= 3 && !hasShownTransactionsHint
    }

    /// Whether to show compound interest hint (first week)
    var shouldShowCompoundInterestHint: Bool {
        guard let created = firstGoalCreatedAt else { return false }
        let daysSinceFirstGoal = Calendar.current.dateComponents([.day], from: created, to: Date()).day ?? 0
        return daysSinceFirstGoal <= 7 && !hasShownCompoundInterestHint
    }

    /// Whether enough data for AI insights teaser (1 month)
    var hasEnoughDataForAI: Bool {
        guard let created = firstGoalCreatedAt else { return false }
        let daysSinceFirstGoal = Calendar.current.dateComponents([.day], from: created, to: Date()).day ?? 0
        return daysSinceFirstGoal >= 30
    }

    // MARK: - Tracking

    func trackDeposit() {
        depositCount += 1
    }

    func trackTransaction() {
        transactionCount += 1
    }

    func trackFirstGoal() {
        if firstGoalCreatedAt == nil {
            firstGoalCreatedAt = Date()
        }
    }
}
