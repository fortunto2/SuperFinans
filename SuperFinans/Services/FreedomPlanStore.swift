//
//  FreedomPlanStore.swift
//  SuperFinans
//
//  App-side owner of the plan. Kept out of the model file because the widget
//  links that file directly and must not drag in WidgetKit or the rate service.
//
//  Every mutation that has a side effect beyond the struct itself lives here as
//  a named method. Views used to do the read-modify-write themselves and also
//  remember which UserDefaults domains to touch, which is how the currency
//  ended up written to one store in some places and both in others.
//

import Foundation
import SwiftUI
import WidgetKit

@MainActor
final class FreedomPlanStore: ObservableObject {

    static let shared = FreedomPlanStore()

    private static let key = FreedomPlanStorage.key

    @Published var plan: FreedomPlan {
        didSet { save() }
    }

    /// Last known rates, shared by every screen that values holdings or shows a
    /// second currency. Seeded from cache so the first frame is never empty.
    @Published private(set) var rateSnapshot: RateSnapshot? = RateService.cached()

    init(defaults: UserDefaults = FreedomPlanStorage.defaults) {
        self.defaults = defaults
        let currency = FreedomPlanStorage.currency(defaults: defaults)
        if let data = defaults.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(FreedomPlan.self, from: data) {
            self.plan = decoded
        } else {
            self.plan = .seeded(currencyCode: currency)
        }
    }

    private let defaults: UserDefaults

    var outcome: FreedomOutcome { FreedomEngine.outcome(for: plan) }

    // MARK: - Intents

    /// The one way to change currency. The ledger screens read the app's own
    /// defaults while the plan and the widget read the App Group suite; those
    /// are physically different plists, so both are written here or they drift.
    func setCurrency(_ code: String) {
        var updated = plan
        updated.currencyCode = code
        updated.displayCurrencyCode = CurrencyClass.isHard(code) ? nil : "USD"
        if let rateSnapshot {
            updated = updated.revaluingHoldings(using: rateSnapshot)
        }
        plan = updated
        FreedomPlanStorage.setCurrency(code, defaults: defaults)
    }

    func addHolding(_ holding: Holding) {
        var updated = plan
        updated.holdings.append(holding)
        plan = revalued(updated)
    }

    func removeHoldings(withIDs ids: Set<UUID>) {
        var updated = plan
        updated.holdings.removeAll { ids.contains($0.id) }
        plan = revalued(updated)
    }

    func addShift(_ shift: ExpenseShift) {
        guard !plan.shifts.contains(where: { $0.label == shift.label }) else { return }
        plan.shifts.append(shift)
    }

    func removeShifts(withIDs ids: Set<UUID>) {
        plan.shifts.removeAll { ids.contains($0.id) }
    }

    /// Refresh rates and revalue in one step — both screens that need rates
    /// needed exactly this, and each had written its own copy of it.
    func refreshRates() async {
        guard let fresh = await RateService.shared.refreshIfNeeded() else { return }
        rateSnapshot = fresh
        if !plan.holdings.isEmpty {
            plan = plan.revaluingHoldings(using: fresh)
        }
    }

    /// Restate the whole plan in another currency at current rates.
    func restate(to code: String) -> Bool {
        guard let rateSnapshot,
              let converted = plan.converted(to: code, using: rateSnapshot) else { return false }
        plan = converted
        FreedomPlanStorage.setCurrency(code, defaults: defaults)
        return true
    }

    // MARK: - Persistence

    private func revalued(_ plan: FreedomPlan) -> FreedomPlan {
        guard let rateSnapshot else { return plan }
        return plan.revaluingHoldings(using: rateSnapshot)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(plan) else { return }
        defaults.set(data, forKey: Self.key)
        // The home-screen number is only useful if it follows the app.
        WidgetCenter.shared.reloadTimelines(ofKind: "FreedomYearWidget")
    }
}
