//
//  FreedomHeroView.swift
//  SuperFinans
//
//  The answer, and the one lever that moves it. Everything else in the app
//  exists to make this number more accurate.
//
//  FreedomEngine.outcome walks up to 600 months of Decimal arithmetic, so it is
//  computed exactly once per render and handed down. As a computed property it
//  was re-read at nine call sites, and again on every tick of the what-if slider.
//

import SwiftUI
import SuperDuperAnalytics

struct FreedomHeroView: View {

    @ObservedObject var store: FreedomPlanStore
    @State private var extraMonthly: Double = 0
    @State private var showSetup = false
    @State private var showEvents = false
    /// Income minus spending for the current month, from real transactions.
    /// Nil until anything has been recorded — a zero would read as "you saved
    /// nothing", which is a different and much worse statement.
    @State private var actualThisMonth: Int64?

    private var plan: FreedomPlan { store.plan }

    private var extraMinor: Int64 {
        Money(amount: Decimal(extraMonthly), currencyCode: plan.currencyCode).minorUnits
    }

    /// Upper bound of the what-if slider: half of monthly spending, floored at 500.
    private var sliderMax: Double {
        let expenses = Money(minorUnits: plan.monthlyExpensesMinor, currencyCode: plan.currencyCode)
        return max(500, (NSDecimalNumber(decimal: expenses.decimalAmount).doubleValue / 2).rounded())
    }

    var body: some View {
        let outcome = FreedomEngine.outcome(for: plan, extraMonthlyMinor: extraMinor)

        return VStack(spacing: 20) {
            headline(outcome)
            target(outcome)
            thisMonth(outcome)
            coverage(outcome)
            whatIf(outcome)
            if !plan.returnAssumptionIsCredible { softCurrencyNote }
            lifeEvents
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
        .sheet(isPresented: $showEvents) {
            LifeEventsView(store: store)
        }
        .task {
            // Gold and foreign savings move with the market, so the plan is
            // revalued whenever fresh rates land — not only when edited.
            await store.refreshRates()
            loadActuals()
        }
    }

    // MARK: - Life events

    /// The plan currently assumes today's spending forever. Saying that out loud
    /// is what makes the feature obvious instead of hidden behind a menu.
    private var lifeEvents: some View {
        Button {
            showEvents = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "timeline.selection")
                VStack(alignment: .leading, spacing: 1) {
                    if plan.shifts.isEmpty {
                        Text("Life won't cost this forever")
                            .font(.subheadline)
                        Text("Children leaving or a mortgage ending moves the year")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(plan.shifts.count) life event\(plan.shifts.count == 1 ? "" : "s")")
                            .font(.subheadline)
                        Text(plan.shifts.sorted { $0.year < $1.year }
                            .map { "\($0.label) \(String($0.year))" }
                            .joined(separator: " · "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }

    // MARK: - This month

    /// The plan says a number; the ledger knows another. Showing both is the
    /// whole point of letting accounts and transactions exist alongside the
    /// estimate — otherwise they are two apps sharing an icon.
    private func thisMonth(_ outcome: FreedomOutcome) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("Plan says")
                Spacer()
                Text(money(plan.monthlySavingsMinor) + "/mo")
                    .monospacedDigit()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            if let actual = actualThisMonth {
                HStack {
                    Text("Set aside this month")
                    Spacer()
                    Text(money(actual))
                        .monospacedDigit()
                        .foregroundStyle(actual >= plan.monthlySavingsMinor
                                         ? Color.incomeGreen : Color.warningAmber)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                if let drift = driftLabel(actual: actual, plannedYear: outcome.year) {
                    Text(drift)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    /// What the year becomes if this month's real pace is the pace from now on.
    private func driftLabel(actual: Int64, plannedYear: Int?) -> String? {
        guard actual != plan.monthlySavingsMinor, let plannedYear else { return nil }
        var asRecorded = plan
        asRecorded.monthlySavingsMinor = actual
        guard let year = FreedomEngine.outcome(for: asRecorded).year, year != plannedYear
        else { return nil }
        return "Keep this pace and the year becomes \(String(year))"
    }

    private func loadActuals() {
        let now = Date()
        let income = CashFlowService.shared.activeIncome(for: now)
        let spent = CashFlowService.shared.totalExpenses(for: now)
        actualThisMonth = (income == 0 && spent == 0) ? nil : income - spent
    }

    // MARK: - Target

    /// The number the whole plan is walking towards. Shown in a second currency
    /// when the first one is not what the person actually thinks in.
    private func target(_ outcome: FreedomOutcome) -> some View {
        VStack(spacing: 2) {
            Text("You need")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(money(outcome.targetAssetsMinor))
                .font(.title3.bold())
                .monospacedDigit()
            if let secondary = secondaryAmount(outcome.targetAssetsMinor) {
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

            if store.rateSnapshot != nil {
                Button {
                    let from = plan.currencyCode
                    if store.restate(to: "USD") {
                        Analytics.track("plan_restated_usd", props: ["from": from])
                    }
                } label: {
                    Text("Restate the plan in USD")
                        .font(.caption.bold())
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warningAmber.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Money formatting

    private func money(_ minor: Int64) -> String {
        Money(minorUnits: minor, currencyCode: plan.currencyCode).formatted
    }

    /// The same amount in the person's second currency, if they kept one.
    private func secondaryAmount(_ minor: Int64) -> String? {
        guard let code = plan.displayCurrencyCode, code != plan.currencyCode,
              let snapshot = store.rateSnapshot,
              let value = snapshot.convert(Double(minor) / 100, from: plan.currencyCode, to: code)
        else { return nil }
        return Money(amount: Decimal(value), currencyCode: code).formatted
    }

    // MARK: - Headline

    private func headline(_ outcome: FreedomOutcome) -> some View {
        VStack(spacing: 4) {
            Text("Financially free in")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let year = outcome.year {
                Text(String(year))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.goalMintDark)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: year)

                HStack(spacing: 6) {
                    if let age = outcome.age {
                        Text("you'll be \(String(age))")
                    }
                    // The dot only earns its place between two things.
                    if outcome.age != nil, let years = outcome.years, years > 0 {
                        Text("·").foregroundStyle(.tertiary)
                    }
                    if let years = outcome.years, years > 0 {
                        Text("\(String(years)) years away")
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

    private func coverage(_ outcome: FreedomOutcome) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Passive income covers")
                Spacer()
                Text(outcome.currentRatio.formatted(.percent.precision(.fractionLength(0))))
                    .monospacedDigit()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            ProgressView(value: outcome.currentRatio)
                .tint(Color.goalMint)
        }
    }

    // MARK: - What-if

    /// The saving is derived from the outcome already computed for this render
    /// rather than by running the engine a second time.
    private func whatIf(_ outcome: FreedomOutcome) -> some View {
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

            if extraMinor > 0,
               let base = FreedomEngine.outcome(for: plan).months,
               let boostedMonths = outcome.months,
               base > boostedMonths {
                Text(savedLabel(months: base - boostedMonths))
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
