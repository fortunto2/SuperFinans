//
//  FreedomSetupView.swift
//  SuperFinans
//
//  Three numbers, one answer. The result updates while you type, so the
//  payoff arrives before you finish filling the form.
//

import SwiftUI
import SuperDuperAnalytics

struct FreedomSetupView: View {

    @ObservedObject var store: FreedomPlanStore
    /// Called once the plan is usable — the caller dismisses or advances.
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var expenses = ""
    @State private var savings = ""
    @State private var monthly = ""
    @State private var birthYear = ""
    @State private var currency = ""
    @State private var showHoldings = false

    /// The currency the fields are being typed in.
    private var activeCurrency: String {
        currency.isEmpty ? store.plan.currencyCode : currency
    }

    private var draft: FreedomPlan {
        var p = store.plan
        p.currencyCode = activeCurrency
        p.monthlyExpensesMinor = minorUnits(expenses)
        p.currentSavingsMinor = minorUnits(savings)
        p.monthlySavingsMinor = minorUnits(monthly)
        p.birthYear = Int(birthYear).flatMap { $0 > 1900 && $0 < 2026 ? $0 : nil }
        return p
    }

    private var outcome: FreedomOutcome { FreedomEngine.outcome(for: draft) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Three numbers and you have your answer. No bank login, no month of receipts.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Asked first: "1200" means nothing until we know what it is.
                    NavigationLink {
                        CurrencyPickerView(selection: $currency) { code in
                            var plan = store.plan
                            plan.currencyCode = code
                            plan.displayCurrencyCode = CurrencyClass.isHard(code) ? nil : "USD"
                            store.plan = plan
                            UserDefaults.standard.set(code, forKey: FreedomPlanStorage.currencyKey)
                            FreedomPlanStorage.defaults.set(code, forKey: FreedomPlanStorage.currencyKey)
                        }
                        .navigationTitle("Your currency")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Currency").font(.headline)
                                Text(CurrencyPickerView.name(for: activeCurrency))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(activeCurrency)
                                .font(.title3.bold())
                                .foregroundStyle(Color.goalMintDark)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    field(
                        title: "What life costs each month",
                        hint: "Rent, food, everything. Rough is fine.",
                        text: $expenses
                    )
                    field(
                        title: "What you already have invested",
                        hint: "Savings, index funds, anything that earns.",
                        text: $savings
                    )
                    Button {
                        showHoldings = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Also in gold or another currency")
                                    .font(.subheadline)
                                Text(holdingsSummary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    field(
                        title: "What you add each month",
                        hint: "Zero is a valid answer.",
                        text: $monthly
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Year you were born")
                            .font(.headline)
                        Text("Optional — it turns the year into an age.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("1990", text: $birthYear)
                            .font(.title2.bold())
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if draft.isConfigured {
                        livePreview
                        pace
                    }
                }
                .padding()
            }
            .navigationTitle("Your freedom year")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let wasConfigured = store.plan.isConfigured
                        store.plan = draft
                        // Categorical only: whether an answer exists, never its size.
                        Analytics.track(
                            wasConfigured ? "plan_updated" : "plan_created",
                            props: [
                                "currency": draft.currencyCode,
                                "reachable": outcome.isReachable ? "yes" : "no",
                                "has_birth_year": draft.birthYear != nil ? "yes" : "no",
                            ]
                        )
                        if !wasConfigured { armMonthlyCheckIn() }
                        onDone()
                        dismiss()
                    }
                    .disabled(!draft.isConfigured)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: seedFromStore)
            .sheet(isPresented: $showHoldings) {
                HoldingsView(store: store)
            }
        }
    }

    private var holdingsSummary: String {
        let plan = store.plan
        if plan.holdings.isEmpty { return "Gold by the gram, or savings held abroad" }
        let units = Set(plan.holdings.map(\.unit)).sorted().joined(separator: ", ")
        let worth = Money(minorUnits: plan.holdingsValueMinor, currencyCode: plan.currencyCode)
        return "\(plan.holdings.count) · \(units) · \(worth.formatted)"
    }

    // MARK: - Pieces

    private func field(title: String, hint: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(hint).font(.caption).foregroundStyle(.secondary)
            MoneyTextField(label: "0", value: text, currencyCode: activeCurrency)
        }
    }

    private var livePreview: some View {
        VStack(spacing: 6) {
            if let year = outcome.year {
                Text("\(String(year))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.goalMintDark)
                if let age = outcome.age {
                    Text("you'll be \(age)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                if let years = outcome.years {
                    Text(years == 0 ? "You're there now" : "\(years) years from today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Not within 50 years")
                    .font(.title3.bold())
                Text("At this rate the money never catches up with the spending. Try a larger monthly amount.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    /// The number people actually act on. The year answers "when"; this answers
    /// "what would I have to do about it", which is the only half you control.
    private var pace: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What it would take")
                .font(.headline)
            ForEach([5, 10, 20], id: \.self) { years in
                HStack {
                    Text("Free in \(String(years)) years")
                    Spacer()
                    if let needed = FreedomEngine.requiredMonthly(for: draft, withinYears: years) {
                        Text(Money(minorUnits: needed, currencyCode: activeCurrency).formatted + "/mo")
                            .monospacedDigit()
                            .foregroundStyle(needed <= draft.monthlySavingsMinor
                                             ? Color.incomeGreen : .primary)
                    } else {
                        Text("out of reach")
                            .foregroundStyle(.tertiary)
                    }
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Helpers

    /// Asked for only after the first real answer, never on launch.
    private func armMonthlyCheckIn() {
        Task {
            let granted = await NotificationService.shared.requestPermission()
            if granted { NotificationService.shared.scheduleMonthlyCheckIn() }
        }
    }

    private func seedFromStore() {
        let p = store.plan
        currency = p.currencyCode
        if p.monthlyExpensesMinor > 0 { expenses = majorString(p.monthlyExpensesMinor) }
        if p.currentSavingsMinor > 0 { savings = majorString(p.currentSavingsMinor) }
        if p.monthlySavingsMinor > 0 { monthly = majorString(p.monthlySavingsMinor) }
        if let y = p.birthYear { birthYear = String(y) }
    }

    /// Accepts both "1 234,50" and "1234.50" — people type what their keyboard gives them.
    private func minorUnits(_ text: String) -> Int64 {
        let cleaned = text
            .replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }
        guard let value = Decimal(string: cleaned) else { return 0 }
        return Money(amount: value, currencyCode: activeCurrency).minorUnits
    }

    private func majorString(_ minor: Int64) -> String {
        let money = Money(minorUnits: minor, currencyCode: activeCurrency)
        return NSDecimalNumber(decimal: money.decimalAmount).stringValue
    }
}
