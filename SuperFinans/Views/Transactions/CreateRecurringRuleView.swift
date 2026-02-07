//
//  CreateRecurringRuleView.swift
//  SuperFinans
//
//  Form for creating a new recurring transaction rule.
//

import SwiftUI

struct CreateRecurringRuleView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var amount = ""
    @State private var isExpense = true
    @State private var note = ""
    @State private var selectedCategory: CategoryDefinition?
    @State private var frequency: RecurringFrequency = .monthly
    @State private var nextDueDate = Date()
    @State private var currencyCode = "USD"

    private let service = RecurringRuleService.shared

    var isValid: Bool {
        !amount.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    MoneyTextField(label: "Amount", value: $amount, currencyCode: currencyCode)

                    Picker("Type", selection: $isExpense) {
                        Text("Expense").tag(true)
                        Text("Income").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    TextField("Description (optional)", text: $note)

                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(CategoryDefinition?.none)
                        ForEach(CategoryDefinition.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.iconName)
                                .tag(CategoryDefinition?.some(cat))
                        }
                    }
                }

                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    DatePicker("First Due Date", selection: $nextDueDate, displayedComponents: .date)
                }
            }
            .navigationTitle("New Recurring Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createRule() }
                        .disabled(!isValid)
                        .bold()
                }
            }
        }
    }

    // MARK: - Actions

    private func createRule() {
        let cleaned = amount.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value > 0 else { return }
        var minorUnits = Int64(value * 100)
        if isExpense { minorUnits = -minorUnits }

        service.createRule(
            amount: minorUnits,
            currencyCode: currencyCode,
            categoryId: selectedCategory?.rawValue,
            note: note.isEmpty ? nil : note,
            frequency: frequency,
            nextDueDate: nextDueDate
        )

        dismiss()
    }
}

#Preview {
    CreateRecurringRuleView()
}
