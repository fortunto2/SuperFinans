//
//  CreateGoalView.swift
//  SuperFinans
//
//  Sheet for creating a new financial goal.
//

import SwiftUI

struct CreateGoalView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var targetAmount = ""
    @State private var targetDate = Date().addingTimeInterval(365 * 24 * 3600)
    @State private var hasTargetDate = true
    @State private var monthlyContribution = ""
    @State private var annualInterestRate = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColorHex = "4ECDC4"
    @State private var showAdvanced = false
    @State private var currencyCode = "USD"
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
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.goalMint)
                                Text("\(account.rateDescription ?? "") will be used for projections")
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
                    // Icon picker
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

                    // Color picker
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

                // Savings & interest
                Section {
                    DisclosureGroup("Savings Plan", isExpanded: $showAdvanced) {
                        MoneyTextField(label: "Monthly Contribution", value: $monthlyContribution, currencyCode: currencyCode)

                        if let account = selectedAccount, account.effectiveAnnualRate > 0 {
                            // Rate from account — read-only
                            HStack {
                                Text("Interest Rate")
                                Spacer()
                                Text(account.rateDescription ?? "")
                                    .foregroundColor(.goalMint)
                            }
                            Text("Rate from \(account.displayName). Change it in account settings.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            // Manual rate input
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

                // Calculator hint
                if isValid && hasTargetDate {
                    Section {
                        let target = parseAmount(targetAmount)
                        let months = targetDate.monthsFromNow()
                        let rate = parseRate(annualInterestRate)
                        let required = calculator.requiredMonthlyContribution(
                            targetAmount: target,
                            currentAmount: 0,
                            annualRate: rate,
                            months: months
                        )
                        let money = Money(minorUnits: required, currencyCode: currencyCode)

                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.warningAmber)
                            Text("Save \(money.formatted)/mo to reach your goal")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createGoal() }
                        .disabled(!isValid)
                        .bold()
                }
            }
            .onChange(of: selectedAccount) { account in
                if let account {
                    // Auto-fill rate from account
                    let rate = account.effectiveAnnualRate
                    if rate > 0 {
                        let pct = rate * 100
                        annualInterestRate = "\(pct)"
                        showAdvanced = true
                    }
                    // Sync currency
                    currencyCode = account.currency
                }
            }
        }
    }

    // MARK: - Actions

    private func createGoal() {
        let target = parseAmount(targetAmount)
        let monthly = parseAmount(monthlyContribution)
        let rate = parseRate(annualInterestRate)

        let goal = goalService.createGoal(
            name: name,
            targetAmount: target,
            currencyCode: currencyCode,
            targetDate: hasTargetDate ? targetDate : nil,
            annualInterestRate: rate,
            monthlyContribution: monthly,
            iconName: selectedIcon,
            colorHex: selectedColorHex
        )

        // Link to account
        if let account = selectedAccount {
            goal.account = account
            goalService.updateGoal(goal)
        }

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

#Preview {
    CreateGoalView()
}
