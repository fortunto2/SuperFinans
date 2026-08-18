//
//  HoldingsView.swift
//  SuperFinans
//
//  Savings that are not in your own currency. Euros in a foreign account, and
//  gold by the gram — which is how a large part of Turkey, India and the Gulf
//  actually saves, and which no FIRE calculator thinks to ask about.
//

import SwiftUI

struct HoldingsView: View {

    @ObservedObject var store: FreedomPlanStore
    @Environment(\.dismiss) private var dismiss

    @State private var showAdd = false

    private var plan: FreedomPlan { store.plan }
    private var snapshot: RateSnapshot? { store.rateSnapshot }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if plan.holdings.isEmpty {
                        Text("Everything is counted in \(plan.currencyCode). Add anything you keep in another currency, or in gold.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(plan.holdings) { holding in
                            row(holding)
                        }
                        .onDelete { offsets in
                            store.removeHoldings(withIDs: Set(offsets.map { plan.holdings[$0].id }))
                        }
                    }
                } header: {
                    Text("Held in something else")
                } footer: {
                    if plan.holdingsValueMinor > 0 {
                        Text("Worth \(Money(minorUnits: plan.holdingsValueMinor, currencyCode: plan.currencyCode).formatted) today, on top of what you entered as savings.")
                    }
                }

                Section {
                    Button {
                        showAdd = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Other savings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await store.refreshRates() }
            .sheet(isPresented: $showAdd) {
                AddHoldingView(store: store)
            }
        }
    }

    private func row(_ holding: Holding) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.amountText(holding))
                    .font(.body)
                if !holding.label.isEmpty {
                    Text(holding.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let snapshot,
               let value = snapshot.convert(holding.amount, from: holding.unit, to: plan.currencyCode) {
                Text(Money(amount: Decimal(value), currencyCode: plan.currencyCode).formatted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } else {
                Text("no rate")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    static func amountText(_ holding: Holding) -> String {
        if Metal.isMetal(holding.unit) {
            return Metal.format(grams: holding.amount)
        }
        return Money(amount: Decimal(holding.amount), currencyCode: holding.unit).formatted
    }

    private func revalue() {
        guard let snapshot else { return }
        store.plan = store.plan.revaluingHoldings(using: snapshot)
    }
}

// MARK: - Add

struct AddHoldingView: View {

    @ObservedObject var store: FreedomPlanStore

    @Environment(\.dismiss) private var dismiss
    @State private var unit = "XAU"
    @State private var amountText = ""
    @State private var label = ""

    private var amount: Double {
        NSDecimalNumber(decimal: Decimal(userInput: amountText) ?? 0).doubleValue
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Kind", selection: $unit) {
                        Text("Gold (grams)").tag(Metal.goldCode)
                        Text("Another currency").tag("USD")
                    }
                    .pickerStyle(.segmented)

                    if !Metal.isMetal(unit) {
                        NavigationLink {
                            CurrencyPickerView(selection: $unit)
                                .navigationTitle("Currency")
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            HStack {
                                Text("Currency")
                                Spacer()
                                Text(unit).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        TextField(Metal.isMetal(unit) ? "12.5" : "1000", text: $amountText)
                            .keyboardType(.decimalPad)
                        Text(Metal.isMetal(unit) ? "g" : unit)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(Metal.isMetal(unit) ? "Grams of gold" : "Amount")
                } footer: {
                    if Metal.isMetal(unit) {
                        Text("Priced from the spot gold market, per gram. A bracelet is not an investment grade bar, so treat this as an estimate.")
                    }
                }

                Section("Label") {
                    TextField(Metal.isMetal(unit) ? "Wedding gold" : "Account abroad", text: $label)
                }
            }
            .navigationTitle("Add savings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addHolding(Holding(unit: unit, amount: amount, label: label))
                        dismiss()
                    }
                    .disabled(amount <= 0)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
