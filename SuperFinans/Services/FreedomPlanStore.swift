//
//  FreedomPlanStore.swift
//  SuperFinans
//
//  App-side owner of the plan. Kept out of the model file because the widget
//  links that file directly and must not drag in WidgetKit or the rate service.
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

    init(defaults: UserDefaults = FreedomPlanStorage.defaults) {
        self.defaults = defaults
        let currency = defaults.string(forKey: "superfinans.currency_code")
            ?? Locale.current.currency?.identifier
            ?? "USD"
        // Older plans were stored before the currency was pinned; follow the app.
        if let data = defaults.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(FreedomPlan.self, from: data) {
            self.plan = decoded
        } else {
            self.plan = .seeded(currencyCode: currency)
        }
    }

    private let defaults: UserDefaults

    var outcome: FreedomOutcome { FreedomEngine.outcome(for: plan) }

    private func save() {
        guard let data = try? JSONEncoder().encode(plan) else { return }
        defaults.set(data, forKey: Self.key)
        // The home-screen number is only useful if it follows the app.
        WidgetCenter.shared.reloadTimelines(ofKind: "FreedomYearWidget")
    }
}
