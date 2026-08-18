//
//  FreedomHeroView.swift
//  SuperFinans
//
//  The answer, and the one lever that moves it. Everything else in the app
//  exists to make this number more accurate.
//

import SwiftUI

struct FreedomHeroView: View {

    @ObservedObject var store: FreedomPlanStore
    @State private var extraMonthly: Double = 0
    @State private var showSetup = false

    private var plan: FreedomPlan { store.plan }

    private var boosted: FreedomOutcome {
        FreedomEngine.outcome(for: plan, extraMonthlyMinor: extraMinor)
    }

    private var extraMinor: Int64 {
        Money(amount: Decimal(extraMonthly), currencyCode: plan.currencyCode).minorUnits
    }

    /// Upper bound of the what-if slider: half of monthly spending, floored at 500.
    private var sliderMax: Double {
        let expenses = Money(minorUnits: plan.monthlyExpensesMinor, currencyCode: plan.currencyCode)
        return max(500, (NSDecimalNumber(decimal: expenses.decimalAmount).doubleValue / 2).rounded())
    }

    var body: some View {
        VStack(spacing: 20) {
            headline
            coverage
            if plan.monthlySavingsMinor >= 0 { whatIf }
            Button {
                showSetup = true
            } label: {
                Label("Adjust the numbers", systemImage: "slider.horizontal.3")
                    .font(.subheadline)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .sheet(isPresented: $showSetup) {
            FreedomSetupView(store: store) { extraMonthly = 0 }
        }
    }

    // MARK: - Headline

    private var headline: some View {
        VStack(spacing: 4) {
            Text("Financially free in")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let year = boosted.year {
                Text(String(year))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.goalMintDark)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: year)

                HStack(spacing: 6) {
                    if let age = boosted.age {
                        Text("you'll be \(age)")
                    }
                    if let years = boosted.years, years > 0 {
                        Text("·").foregroundStyle(.tertiary)
                        Text("\(years) years away")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else {
                Text("Not yet")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("At this rate the money never overtakes the spending.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Coverage

    private var coverage: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Passive income covers")
                Spacer()
                Text(boosted.currentRatio.formatted(.percent.precision(.fractionLength(0))))
                    .monospacedDigit()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            ProgressView(value: boosted.currentRatio)
                .tint(Color.goalMint)
        }
    }

    // MARK: - What-if

    private var whatIf: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Save extra per month")
                Spacer()
                Text(Money(minorUnits: extraMinor, currencyCode: plan.currencyCode).formatted)
                    .monospacedDigit()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Slider(value: $extraMonthly, in: 0...sliderMax, step: max(10, (sliderMax / 20).rounded()))
                .tint(Color.goalMintDark)

            if let saved = FreedomEngine.monthsSaved(for: plan, extraMonthlyMinor: extraMinor),
               saved > 0 {
                Text(savedLabel(months: saved))
                    .font(.footnote.bold())
                    .foregroundStyle(Color.incomeGreen)
            }
        }
    }

    private func savedLabel(months: Int) -> String {
        let years = months / 12
        let rest = months % 12
        if years > 0 && rest > 0 { return "\(years)y \(rest)m earlier" }
        if years > 0 { return "\(years) years earlier" }
        return "\(months) months earlier"
    }
}

// MARK: - Empty state

struct FreedomPromptView: View {

    @ObservedObject var store: FreedomPlanStore
    @State private var showSetup = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 44))
                .foregroundStyle(Color.goalMint)

            Text("When can you stop working?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Answer three questions and find out. Under a minute, no bank connection.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showSetup = true
            } label: {
                Text("Find my year")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.goalMintDark)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .sheet(isPresented: $showSetup) {
            FreedomSetupView(store: store) {}
        }
    }
}
