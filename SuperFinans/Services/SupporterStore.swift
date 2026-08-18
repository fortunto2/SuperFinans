//
//  SupporterStore.swift
//  SuperFinans
//
//  StoreKit 2, one non-consumable, no subscription.
//
//  Nothing that answers the question is behind it. The year, the slider, life
//  events, the widget and all 156 currencies stay free — a calculator people
//  cannot try is a calculator nobody recommends. What the purchase buys is
//  cosmetic and quantitative: alternate icons, the three-account limit lifted,
//  and a line in Settings saying you paid for this.
//

import Foundation
import StoreKit

@MainActor
final class SupporterStore: ObservableObject {

    static let shared = SupporterStore()

    /// Non-consumable, matched in App Store Connect.
    static let productID = "co.superduperai.superfinans.supporter"

    @Published private(set) var product: Product?
    @Published private(set) var isSupporter = false
    @Published private(set) var isPurchasing = false
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        // Entitlements can change outside the app — a family-sharing grant, a
        // refund, a restore on another device — so listen for the life of the app.
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
                await self?.refresh()
            }
        }
        Task { await refresh() }
    }

    deinit { updatesTask?.cancel() }

    // MARK: - Loading

    func load() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// The only source of truth for entitlement — never a stored boolean, which
    /// is what makes refunds and shared purchases behave correctly.
    func refresh() async {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                isSupporter = true
                return
            }
        }
        isSupporter = false
    }

    // MARK: - Buying

    @discardableResult
    func purchase() async -> Bool {
        guard let product else { return false }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    lastError = "That purchase could not be verified."
                    return false
                }
                await transaction.finish()
                await refresh()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Apple requires a restore path even for a single non-consumable.
    func restore() async {
        do {
            try await AppStore.sync()
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Formatted price straight from StoreKit, so it is right in every storefront.
    var displayPrice: String { product?.displayPrice ?? "" }
}
