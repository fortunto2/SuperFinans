//
//  ProgressRingView.swift
//  SuperFinans
//
//  Animated circular progress ring for goal visualization.
//

import SwiftUI

struct ProgressRingView: View {

    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color
    var showPercentage: Bool = true

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.7), color]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * animatedProgress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // End cap glow
            if animatedProgress > 0.02 {
                Circle()
                    .fill(color)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(360 * animatedProgress - 90))
                    .shadow(color: color.opacity(0.5), radius: 4)
            }

            // Center text
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(min(progress, 1.0) * 100))")
                        .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.system(size: size * 0.1, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = min(progress, 1.0)
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = min(newValue, 1.0)
            }
        }
    }
}

// MARK: - Compact variant for list cells

struct CompactProgressRing: View {
    let progress: Double
    let color: Color

    var body: some View {
        ProgressRingView(
            progress: progress,
            lineWidth: 4,
            size: 44,
            color: color,
            showPercentage: true
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        ProgressRingView(progress: 0.65, lineWidth: 12, size: 160, color: .goalMint)
        ProgressRingView(progress: 0.35, lineWidth: 8, size: 100, color: .goalBlue)
        CompactProgressRing(progress: 0.8, color: .goalPurple)
    }
    .padding()
    .background(Color.navyPrimary)
}
