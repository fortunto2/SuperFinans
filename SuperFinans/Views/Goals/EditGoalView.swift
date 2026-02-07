//
//  EditGoalView.swift
//  SuperFinans
//
//  Sheet for editing an existing financial goal.
//

import SwiftUI

struct EditGoalView: View {

    @Environment(\.dismiss) private var dismiss

    let goal: GoalEntity

    @State private var name: String
    @State private var targetAmount: String
    @State private var targetDate: Date
    @State private var hasTargetDate: Bool
    @State private var monthlyContribution: String
    @State private var annualInterestRate: String
    @State private var selectedIcon: String
    @State private var selectedColorHex: String
    @State private var currencyCode: String
    @State private var selectedAccount: AccountEntity?

    private let goalService = GoalService.shared
    private let calculator = FinancialCalculator.shared
    private let accounts = AccountService.shared.fetchAccounts()

    private let iconOptions = [
        "star.fill", "shield.fill", "house.fill", "car.fill",
        "airplane", "graduationcap.fill", "heart.fill", "gift.fill",
        "dollarsign.circle.fill", "beach.umbrella.fill", "figure.and.child.holdinghands",
        "laptopcomputer", "stethoscope", "paintbrush.fill", "music.note"
    ]

    init(goal: GoalEntity) {
        self.goal = goal
        _name = State(initialValue: goal.displayName)
        let targetMajor = Double(goal.targetAmountMinorUnits) / 100.0
        _targetAmount = State(initialValue: targetMajor > 0 ? String(format: "%.2f", targetMajor) : "")
        _targetDate = State(initialValue: goal.targetDate ?? Date().addingTimeInterval(365 * 24 * 3600))
        _hasTargetDate = State(initialValue: goal.targetDate != nil)
        let monthlyMajor = Double(goal.monthlyContributionMinorUnits) / 100.0
        _monthlyContribution = State(initialValue: monthlyMajor > 0 ? String(format: "%.2f", monthlyMajor) : "")
        let rate = goal.interestRate * 100
        _annualInterestRate = State(initialValue: rate > 0 ? "\(rate)" : "")
        _selectedIcon = State(initialValue: goal.iconName ?? "star.fill")
        _selectedColorHex = State(initialValue: goal.colorHex ?? "4ECDC4")
        _currencyCode = State(initialValue: goal.currency)
        _selectedAccount = State(initialValue: goal.account)
    }

    var isValid: Bool {
        !name.isEmpty && !targetAmount.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Account selection
                if !accounts.isEmpty {
                    Section("Account") {
                        Picker("Linked Account", selection: $selectedAccount) {
                            Text("None").tag(AccountEntity?.none)
                            ForEach(accounts, id: \.id) { account in
                                HStack {
                                    Image(systemName: account.accountType.iconName)
                                    Text(account.displayName)
                                    if let rateDesc = account.rateDescription {
                                        Text("— \(rateDesc)")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(AccountEntity?.some(account))
                            }
                        }

                        if let account = selectedAccount, account.effectiveAnnualRate > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "percent")
                                    .foregroundColor(.goalMint)
                                Text("Rate from \(account.displayName): \(account.rateDescription ?? "")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Basic info
                Section("Goal Details") {
                    TextField("Goal Name", text: $name)
                    MoneyTextField(label: "Target Amount", value: $targetAmount, currencyCode: currencyCode)

                    Toggle("Set a Target Date", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("Target Date", selection: $targetDate, in: Date()..., displayedComponents: .date)
                    }
                }

                // Icon & color picker
                Section("Appearance") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.goalMint.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedIcon == icon ? Color.goalMint : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)

                    HStack(spacing: 12) {
                        ForEach(Array(zip(Color.goalColorOptions, Color.goalColorHexOptions)), id: \.1) { color, hex in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColorHex == hex ? 3 : 0)
                                )
                                .scaleEffect(selectedColorHex == hex ? 1.15 : 1.0)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedColorHex = hex
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Advanced (compound interest)
                Section {
                    DisclosureGroup("Compound Interest") {
                        MoneyTextField(label: "Monthly Contribution", value: $monthlyContribution, currencyCode: currencyCode)
                        HStack {
                            Text("Annual Interest Rate")
                            Spacer()
                            TextField("0.0", text: $annualInterestRate)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("%")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveGoal() }
                        .disabled(!isValid)
                        .bold()
                }
            }
            .onChange(of: selectedAccount) { account in
                if let account {
                    let rate = account.effectiveAnnualRate
                    if rate > 0 {
                        let pct = rate * 100
                        annualInterestRate = "\(pct)"
                    }
                    currencyCode = account.currency
                }
            }
        }
    }

    // MARK: - Actions

    private func saveGoal() {
        goal.name = name
        goal.targetAmountMinorUnits = parseAmount(targetAmount)
        goal.targetDate = hasTargetDate ? targetDate : nil
        goal.monthlyContributionMinorUnits = parseAmount(monthlyContribution)
        goal.annualInterestRate = NSDecimalNumber(decimal: parseRate(annualInterestRate))
        goal.iconName = selectedIcon
        goal.colorHex = selectedColorHex
        goal.account = selectedAccount

        goalService.updateGoal(goal)
        dismiss()
    }

    // MARK: - Parsing

    private func parseAmount(_ string: String) -> Int64 {
        let cleaned = string.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleaned), amount > 0 else { return 0 }
        return Int64(amount * 100)
    }

    private func parseRate(_ string: String) -> Decimal {
        let cleaned = string.replacingOccurrences(of: ",", with: ".")
        guard let rate = Double(cleaned), rate > 0 else { return 0 }
        return Decimal(rate) / Decimal(100)
    }
}
