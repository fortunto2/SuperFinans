//
//  PremiumManager.swift
//  SuperFinans
//
//  There is no premium tier. The one purchase is a supporter payment, and it
//  unlocks nothing that answers the question — see SupporterStore.
//
//  This type survives only because several view models ask `isPremium` to
//  decide whether to show a nudge. It now reports the supporter purchase, and
//  `canAccess` always says yes: every limit it once described was unreachable
//  in the UI, and adding one in order to sell its removal is not the deal.
//

import Foundation

@MainActor
final class PremiumManager: ObservableObject {

    static let shared = PremiumManager()

    private init() {}

    var isPremium: Bool { SupporterStore.shared.isSupporter }

    /// Nothing is gated. Kept so call sites read honestly instead of being
    /// deleted one by one across view models that will be rewritten anyway.
    func canAccess(_ feature: PremiumFeature) -> Bool { true }

    func refreshStatus() {
        Task { await SupporterStore.shared.refresh() }
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
