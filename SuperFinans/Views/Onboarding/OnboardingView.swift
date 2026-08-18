//
//  OnboardingView.swift
//  SuperFinans
//
//  First launch. Three screens, and the last one hands straight over to the
//  three questions — the only thing this app asks of anyone.
//

import SwiftUI

struct OnboardingView: View {

    @Binding var isCompleted: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "When can you stop working?",
            subtitle: "Not a budget. Not a spending report. One number: the year your money starts covering your life instead of your salary.",
            sfSymbol: "flag.checkered",
            color: .goalMint
        ),
        OnboardingPage(
            title: "Three numbers, one minute",
            subtitle: "What life costs, what you have invested, what you add each month. No bank login, no month of collecting receipts before the app says anything.",
            sfSymbol: "list.number",
            color: .goalBlue
        ),
        OnboardingPage(
            title: "Nothing leaves the phone",
            subtitle: "No account, no ads, and not one amount you type ever leaves the phone — the arithmetic runs here. An anonymous launch counter is the only thing sent, and Settings turns it off.",
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
                        Text(currentPage < pages.count - 1 ? "Next" : "Find my year")
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
        // Hand over to the three questions rather than dropping the person on an
        // empty dashboard — the promise on screen one is one tap from being kept.
        UserDefaults.standard.set(true, forKey: OnboardingView.pendingSetupKey)
        withAnimation(.easeInOut(duration: 0.3)) {
            isCompleted = true
        }
    }

    /// Read once by the dashboard, then cleared.
    static let pendingSetupKey = "superfinans.pending_freedom_setup"
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
