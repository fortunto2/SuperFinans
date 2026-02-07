//
//  SuperFinansPaywallView.swift
//  SuperFinans
//
//  Custom paywall wrapping SuperDuperAiAuth's PaywallView
//  with SuperFinans branding (navy + mint).
//

import SwiftUI
import SuperDuperAiAuth

// MARK: - SuperFinans Paywall Theme

struct SuperFinansPaywallTheme: PaywallTheme {
    var backgroundColor: Color { Color.navyPrimary }
    var cardBackground: Color { Color.navyCard }
    var accentColor: Color { Color.goalMint }
    var textPrimary: Color { .white }
    var textSecondary: Color { Color.white.opacity(0.7) }
    var textTertiary: Color { Color.white.opacity(0.5) }
    var buttonText: Color { Color.navyPrimary }
    var cornerRadius: CGFloat { 16 }
    var iconGradient: [Color] { [Color.goalMint, Color.goalMintDark] }
}

// MARK: - Paywall View

struct SuperFinansPaywallView: View {

    @Environment(\.dismiss) private var dismiss

    private let features: [PaywallFeature] = [
        PaywallFeature(icon: "star.fill", text: "Unlimited savings goals"),
        PaywallFeature(icon: "person.3.fill", text: "Family sharing (up to 6)"),
        PaywallFeature(icon: "sparkles", text: "AI-powered insights"),
        PaywallFeature(icon: "doc.text.fill", text: "CSV import from any bank"),
        PaywallFeature(icon: "coloncurrencysign.circle.fill", text: "Multi-currency support"),
        PaywallFeature(icon: "chart.bar.fill", text: "12-month reports & trends"),
    ]

    var body: some View {
        if let storeKit = SuperDuperAiAuth.shared.storeKit {
            PaywallView(
                storeKit: storeKit,
                theme: SuperFinansPaywallTheme(),
                title: "Unlock Premium",
                subtitle: "One-time purchase. No subscription. Ever.",
                headerIcon: "crown.fill",
                features: features,
                productID: "superfinans.premium.lifetime",
                priceSubtitle: "Pay once, use forever",
                purchaseButtonText: "Buy Premium",
                onPurchaseSimple: {
                    PremiumManager.shared.refreshStatus()
                    dismiss()
                },
                onRestore: {
                    try? await SuperDuperAiAuth.shared.restorePurchases()
                    PremiumManager.shared.refreshStatus()
                    dismiss()
                },
                onDismiss: { dismiss() }
            )
        } else {
            // Fallback if StoreKit not configured
            VStack(spacing: 16) {
                Text("Premium not available")
                    .font(.headline)
                Button("Dismiss") { dismiss() }
            }
        }
    }
}

#Preview {
    SuperFinansPaywallView()
}
