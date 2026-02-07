//
//  PremiumManager.swift
//  SuperFinans
//
//  Centralized premium status check via SuperDuperAiAuth.
//  All features unlocked in DEBUG builds.
//

import Foundation
import SuperDuperAiAuth

@MainActor
final class PremiumManager: ObservableObject {

    static let shared = PremiumManager()

    @Published var isPremium: Bool = false

    private init() {
        refreshStatus()
    }

    func refreshStatus() {
        #if DEBUG
        isPremium = true
        #else
        isPremium = SuperDuperAiAuth.shared.subscription.tier == .lifetime
        #endif
    }

    /// Check if a feature requiring Premium is accessible
    func canAccess(_ feature: PremiumFeature) -> Bool {
        #if DEBUG
        return true
        #else
        if isPremium { return true }
        switch feature {
        case .unlimitedGoals:
            return GoalService.shared.activeGoalCount() < 1
        case .unlimitedAccounts:
            return AccountService.shared.accountCount() < 3
        case .csvImport, .multiCurrency, .familySync, .aiInsights:
            return false
        case .customCategories:
            return false
        case .extendedReports:
            return false
        }
        #endif
    }
}

enum PremiumFeature {
    case unlimitedGoals
    case unlimitedAccounts
    case csvImport
    case multiCurrency
    case familySync
    case aiInsights
    case customCategories
    case extendedReports
}
