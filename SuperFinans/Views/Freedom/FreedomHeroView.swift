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
    @State private var snapshot: RateSnapshot? = RateService.cached()
    @State private var switching = false

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
            target
            coverage
            if plan.monthlySavingsMinor >= 0 { whatIf }
            if !plan.returnAssumptionIsCredible { softCurrencyNote }
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
        .task {
            snapshot = await RateService.shared.refreshIfNeeded()
        }
    }

    // MARK: - Target

    /// The number the whole plan is walking towards. Shown in a second currency
    /// when the first one is not what the person actually thinks in.
    private var target: some View {
        VStack(spacing: 2) {
            Text("You need")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(money(boosted.targetAssetsMinor))
                .font(.title3.bold())
                .monospacedDigit()
            if let secondary = secondaryAmount(boosted.targetAssetsMinor) {
                Text("≈ \(secondary)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Soft currency

    /// Says the quiet part out loud instead of quietly producing a wrong year.
    private var softCurrencyNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(plan.currencyCode) and a 7% return")
                .font(.footnote.bold())
            Text("7% is what a dollar-denominated market returns over decades. In \(plan.currencyCode) that figure quietly ignores inflation, and over 20 years the error is measured in years.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if snapshot != nil {
                Button {
                    switchToDollars()
                } label: {
                    Text(switching ? "Converting…" : "Restate the plan in USD")
                        .font(.caption.bold())
                }
                .disabled(switching)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warningAmber.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func switchToDollars() {
        guard let snapshot, let converted = plan.converted(to: "USD", using: snapshot) else { return }
        switching = true
        store.plan = converted
        switching = false
    }

    // MARK: - Money formatting

    private func money(_ minor: Int64) -> String {
        Money(minorUnits: minor, currencyCode: plan.currencyCode).formatted
    }

    /// The same amount in the person's second currency, if they kept one.
    private func secondaryAmount(_ minor: Int64) -> String? {
        guard let code = plan.displayCurrencyCode, code != plan.currencyCode,
              let snapshot,
              let value = snapshot.convert(Double(minor) / 100, from: plan.currencyCode, to: code)
        else { return nil }
        return Money(amount: Decimal(value), currencyCode: code).formatted
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
