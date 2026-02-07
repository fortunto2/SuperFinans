//
//  RecurringRulesView.swift
//  SuperFinans
//
//  List of recurring transaction rules.
//

import SwiftUI

struct RecurringRulesView: View {

    @State private var rules: [RecurringRuleEntity] = []
    @State private var showCreateRule = false

    private let service = RecurringRuleService.shared

    var body: some View {
        List {
            if rules.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "repeat.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No Recurring Rules")
                        .font(.headline)
                    Text("Create rules for regular income or expenses like salary, rent, or subscriptions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(rules, id: \.id) { rule in
                    recurringRuleRow(rule)
                }
                .onDelete(perform: deleteRules)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Recurring Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateRule = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateRule) {
            loadRules()
        } content: {
            CreateRecurringRuleView()
        }
        .onAppear { loadRules() }
    }

    // MARK: - Row

    private func recurringRuleRow(_ rule: RecurringRuleEntity) -> some View {
        HStack(spacing: 12) {
            // Category icon
            if let catId = rule.categoryId, let category = CategoryDefinition(rawValue: catId) {
                Image(systemName: category.iconName)
                    .font(.body)
                    .frame(width: 36, height: 36)
                    .background(category.color.opacity(0.15))
                    .clipShape(Circle())
            } else {
                Image(systemName: "repeat.circle.fill")
                    .font(.body)
                    .frame(width: 36, height: 36)
                    .background(Color.goalMint.opacity(0.15))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.note ?? "Recurring")
                    .font(.subheadline)
                Text(rule.recurringFrequency.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(rule.templateAmount.formatted)
                    .font(.subheadline.bold())
                    .foregroundColor(rule.templateAmountMinorUnits > 0 ? .incomeGreen : .expenseRed)
                if let next = rule.nextDueDate {
                    Text("Next: \(next.mediumFormatted)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Actions

    private func loadRules() {
        rules = service.fetchAllRules()
    }

    private func deleteRules(at offsets: IndexSet) {
        for index in offsets {
            service.deleteRule(rules[index])
        }
        loadRules()
    }
}

#Preview {
    NavigationStack {
        RecurringRulesView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
