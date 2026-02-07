//
//  PremiumBadgeView.swift
//  SuperFinans
//
//  Small badge indicating a feature requires Premium.
//

import SwiftUI

struct PremiumBadgeView: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption2)
            Text("Premium")
                .font(.caption2.bold())
        }
        .foregroundColor(.goalMint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.goalMint.opacity(0.15))
        .clipShape(Capsule())
    }
}

#Preview {
    PremiumBadgeView()
        .padding()
        .background(Color.navyPrimary)
}
