//
//  HintBannerView.swift
//  SuperFinans
//
//  Dismissable hint banner for progressive disclosure.
//

import SwiftUI

struct HintBannerView: View {

    let icon: String
    let message: String
    var color: Color = .goalMint
    let onDismiss: () -> Void

    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isVisible = false
                    }
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2.bold())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HintBannerView(
            icon: "list.bullet.rectangle.portrait",
            message: "Track your spending in the Transactions tab.",
            color: .goalBlue
        ) {}

        HintBannerView(
            icon: "chart.line.uptrend.xyaxis",
            message: "Enable compound interest to see your money grow faster.",
            color: .goalMint
        ) {}
    }
    .padding()
}
