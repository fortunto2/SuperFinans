//
//  OnboardingView.swift
//  SuperFinans
//
//  3-screen onboarding flow shown on first launch.
//

import SwiftUI

struct OnboardingView: View {

    @Binding var isCompleted: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Track Your Financial Goals",
            subtitle: "Set savings goals with target amounts and dates. Watch your progress grow with beautiful animated rings.",
            sfSymbol: "star.fill",
            color: .goalMint
        ),
        OnboardingPage(
            title: "See Your Money Grow",
            subtitle: "Compound interest calculator shows how your savings accelerate over time. Adjust contributions and see the impact instantly.",
            sfSymbol: "chart.line.uptrend.xyaxis",
            color: .goalBlue
        ),
        OnboardingPage(
            title: "Private by Design",
            subtitle: "Your data stays on your device. No accounts required, no tracking, no ads. iCloud sync keeps your devices in sync privately.",
            sfSymbol: "lock.shield.fill",
            color: .goalPurple
        )
    ]

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") { completeOnboarding() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                }

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        onboardingPage(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicator + button
                VStack(spacing: 24) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.goalMint : Color.gray.opacity(0.3))
                                .frame(width: index == currentPage ? 10 : 8)
                                .frame(height: index == currentPage ? 10 : 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }

                    // Button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.mintGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Page

    private func onboardingPage(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: page.sfSymbol)
                .font(.system(size: 80))
                .foregroundStyle(page.color.gradient)
                .padding(.bottom, 16)

            // Title
            Text(page.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            // Subtitle
            Text(page.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isCompleted = true
        }
    }
}

// MARK: - Page Model

struct OnboardingPage {
    let title: String
    let subtitle: String
    let sfSymbol: String
    let color: Color
}

#Preview {
    OnboardingView(isCompleted: .constant(false))
}
