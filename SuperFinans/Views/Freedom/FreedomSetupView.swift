//
//  FreedomSetupView.swift
//  SuperFinans
//
//  Three numbers, one answer. The result updates while you type, so the
//  payoff arrives before you finish filling the form.
//

import SwiftUI

struct FreedomSetupView: View {

    @ObservedObject var store: FreedomPlanStore
    /// Called once the plan is usable — the caller dismisses or advances.
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var expenses = ""
    @State private var savings = ""
    @State private var monthly = ""
    @State private var birthYear = ""

    private var draft: FreedomPlan {
        var p = store.plan
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
        }
    }

    // MARK: - Pieces

    private func field(title: String, hint: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(hint).font(.caption).foregroundStyle(.secondary)
            MoneyTextField(label: "0", value: text, currencyCode: store.plan.currencyCode)
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
        return Money(amount: value, currencyCode: store.plan.currencyCode).minorUnits
    }

    private func majorString(_ minor: Int64) -> String {
        let money = Money(minorUnits: minor, currencyCode: store.plan.currencyCode)
        return NSDecimalNumber(decimal: money.decimalAmount).stringValue
    }
}
