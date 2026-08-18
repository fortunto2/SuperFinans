//
//  LifeEventsView.swift
//  SuperFinans
//
//  What life will cost is not a constant. Children grow up, a mortgage ends,
//  a pension starts — and each of those moves the freedom year by years, not
//  months. Every other FIRE calculator models spending as flat forever, which
//  is the single biggest lie in the arithmetic.
//

import SwiftUI

struct LifeEventsView: View {

    @ObservedObject var store: FreedomPlanStore
    @Environment(\.dismiss) private var dismiss

    @State private var showCustom = false

    private var plan: FreedomPlan { store.plan }
    private var thisYear: Int { Calendar.current.component(.year, from: Date()) }

    private var baseline: FreedomOutcome {
        var bare = plan
        bare.shifts = []
        return FreedomEngine.outcome(for: bare)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if plan.shifts.isEmpty {
                        Text("Nothing added yet — the plan assumes you spend the same amount every month until the day you stop working.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(plan.shifts.sorted { $0.year < $1.year }) { shift in
                            row(shift)
                        }
                        .onDelete(perform: delete)
                    }
                } header: {
                    Text("Your timeline")
                } footer: {
                    if let effect = totalEffect {
                        Text(effect).foregroundStyle(Color.incomeGreen)
                    }
                }

                Section("Add") {
                    ForEach(ExpenseShift.presets(currentYear: thisYear)) { preset in
                        Button {
                            add(preset)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.label)
                                    Text("\(preset.year) · \(signed(preset.percent))% spending")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.goalMintDark)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showCustom = true
                    } label: {
                        Label("Something else", systemImage: "square.and.pencil")
                    }
                }
            }
            .navigationTitle("Life events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCustom) {
                CustomShiftView(store: store, defaultYear: thisYear + 5)
            }
        }
    }

    // MARK: - Rows

    private func row(_ shift: ExpenseShift) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(shift.label)
            HStack(spacing: 6) {
                Text(String(shift.year))
                Text("·")
                Text("\(signed(shift.percent))% spending")
                if let saved = effect(of: shift) {
                    Text("·")
                    Text(saved).foregroundStyle(Color.incomeGreen)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Effect

    /// What this one event is worth, measured by removing it from the plan.
    private func effect(of shift: ExpenseShift) -> String? {
        var without = plan
        without.shifts.removeAll { $0.id == shift.id }
        guard let with = FreedomEngine.outcome(for: plan).months,
              let withoutMonths = FreedomEngine.outcome(for: without).months
        else { return nil }
        let saved = withoutMonths - with
        guard saved > 0 else { return nil }
        return saved >= 12 ? "\(saved / 12)y earlier" : "\(saved)m earlier"
    }

    private var totalEffect: String? {
        guard !plan.shifts.isEmpty,
              let base = baseline.months,
              let now = FreedomEngine.outcome(for: plan).months,
              base > now
        else { return nil }
        let saved = base - now
        let years = saved / 12, months = saved % 12
        let span = years > 0 ? "\(years) year\(years == 1 ? "" : "s")" : "\(months) months"
        return "Together these bring freedom \(span) forward."
    }

    // MARK: - Mutation

    private func add(_ preset: ExpenseShift) {
        guard !plan.shifts.contains(where: { $0.label == preset.label }) else { return }
        store.plan.shifts.append(preset)
    }

    private func delete(at offsets: IndexSet) {
        let sorted = plan.shifts.sorted { $0.year < $1.year }
        let ids = offsets.map { sorted[$0].id }
        store.plan.shifts.removeAll { ids.contains($0.id) }
    }

    private func signed(_ percent: Int) -> String {
        percent > 0 ? "+\(percent)" : "\(percent)"
    }
}

// MARK: - Custom event

struct CustomShiftView: View {

    @ObservedObject var store: FreedomPlanStore
    let defaultYear: Int

    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var year: Double = 0
    @State private var percent: Double = -20

    private var resolvedYear: Int {
        year == 0 ? defaultYear : Int(year)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What changes") {
                    TextField("Youngest finishes university", text: $label)
                }
                Section("When") {
                    Stepper("\(resolvedYear)", value: Binding(
                        get: { Double(resolvedYear) },
                        set: { year = $0 }
                    ), in: Double(defaultYear - 5)...Double(defaultYear + 40), step: 1)
                }
                Section {
                    Slider(value: $percent, in: -80...50, step: 5)
                    Text("\(Int(percent) > 0 ? "+" : "")\(Int(percent))% of what you spend today")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Effect on monthly spending")
                }
            }
            .navigationTitle("New event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.plan.shifts.append(
                            ExpenseShift(year: resolvedYear, percent: Int(percent),
                                         label: label.isEmpty ? "Spending changes" : label)
                        )
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
