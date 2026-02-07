//
//  AccountsManagementView.swift
//  SuperFinans
//
//  List of financial accounts with create/edit support.
//  Supports account types: checking, savings, investment, crypto, credit, cash.
//

import SwiftUI

struct AccountsManagementView: View {

    @State private var accounts: [AccountEntity] = []
    @State private var showCreateAccount = false
    @State private var editingAccount: AccountEntity?

    private let service = AccountService.shared

    var body: some View {
        List {
            if accounts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "building.columns")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No Accounts")
                        .font(.headline)
                    Text("Add your bank accounts, brokerages, and crypto wallets to track balances and link goals.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(accounts, id: \.id) { account in
                    Button {
                        editingAccount = account
                    } label: {
                        accountRow(account)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteAccounts)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateAccount = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateAccount) {
            loadAccounts()
        } content: {
            AccountFormView(mode: .create)
        }
        .sheet(item: $editingAccount) { account in
            AccountFormView(mode: .edit(account))
        }
        .onChange(of: editingAccount) { newValue in
            if newValue == nil { loadAccounts() }
        }
        .onAppear { loadAccounts() }
    }

    // MARK: - Row

    private func accountRow(_ account: AccountEntity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: account.accountType.iconName)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(Color(hexString: account.colorHex ?? "42A5F5").opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayName)
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    Text(account.accountType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let rateDesc = account.rateDescription {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(rateDesc)
                            .font(.caption)
                            .foregroundColor(.goalMint)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(account.balance.formatted)
                    .font(.subheadline.bold())
                Text(account.currency)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Actions

    private func loadAccounts() {
        accounts = service.fetchAccounts()
    }

    private func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            service.deleteAccount(accounts[index])
        }
        loadAccounts()
    }
}

// MARK: - Account Form (Create / Edit)

struct AccountFormView: View {

    enum Mode {
        case create
        case edit(AccountEntity)
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var accountType: AccountType
    @State private var accountGroup: AccountGroup
    @State private var currencyCode: String
    @State private var rateString: String
    @State private var benchmarkTicker: String
    @State private var selectedColorHex: String
    @State private var monthlyPaymentString: String
    @State private var debtRateString: String

    private let service = AccountService.shared

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _accountType = State(initialValue: .checking)
            _accountGroup = State(initialValue: .personal)
            _currencyCode = State(initialValue: "USD")
            _rateString = State(initialValue: "")
            _benchmarkTicker = State(initialValue: "")
            _selectedColorHex = State(initialValue: "42A5F5")
            _monthlyPaymentString = State(initialValue: "")
            _debtRateString = State(initialValue: "")
        case .edit(let account):
            _name = State(initialValue: account.displayName)
            _accountType = State(initialValue: account.accountType)
            _accountGroup = State(initialValue: account.accountGroup)
            _currencyCode = State(initialValue: account.currency)
            let rate = account.effectiveAnnualRate * 100
            _rateString = State(initialValue: rate > 0 ? "\(rate)" : "")
            _benchmarkTicker = State(initialValue: account.benchmarkTicker ?? "")
            _selectedColorHex = State(initialValue: account.colorHex ?? "42A5F5")
            let payment = Money(minorUnits: account.monthlyPaymentMinorUnits, currencyCode: account.currency)
            _monthlyPaymentString = State(initialValue: account.monthlyPaymentMinorUnits > 0 ? payment.shortFormatted : "")
            let debtRate = (account.annualDebtInterestRate?.decimalValue ?? 0) * 100
            _debtRateString = State(initialValue: debtRate > 0 ? "\(debtRate)" : "")
        }
    }

    var isValid: Bool {
        !name.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account Name", text: $name)

                    Picker("Group", selection: $accountGroup) {
                        ForEach(AccountGroup.allCases, id: \.self) { group in
                            Label(group.displayName, systemImage: group.icon)
                                .tag(group)
                        }
                    }

                    Picker("Type", selection: $accountType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }

                    Picker("Currency", selection: $currencyCode) {
                        Text("USD — US Dollar").tag("USD")
                        Text("EUR — Euro").tag("EUR")
                        Text("GBP — British Pound").tag("GBP")
                        Text("CAD — Canadian Dollar").tag("CAD")
                        Text("AUD — Australian Dollar").tag("AUD")
                        Text("JPY — Japanese Yen").tag("JPY")
                        Text("RUB — Russian Ruble").tag("RUB")
                        Text("BTC — Bitcoin").tag("BTC")
                        Text("ETH — Ethereum").tag("ETH")
                    }
                }

                // Rate section — only for types that support it
                if accountType.supportsRate {
                    Section(accountType.rateLabel) {
                        HStack {
                            TextField(accountType.ratePlaceholder, text: $rateString)
                                .keyboardType(.decimalPad)
                            Text("% per year")
                                .foregroundStyle(.secondary)
                        }

                        if accountType == .investment || accountType == .crypto {
                            TextField("Benchmark (e.g. S&P 500, BTC)", text: $benchmarkTicker)
                        }

                        // Hints
                        switch accountType {
                        case .savings:
                            Text("Enter your bank's APY. This will auto-fill into goals linked to this account.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        case .investment:
                            Text("Historical S&P 500 average: ~10%. This is an estimate for projections, not guaranteed.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        case .crypto:
                            Text("Crypto returns are highly volatile. Use a conservative estimate for planning.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        default:
                            EmptyView()
                        }
                    }
                }

                // Liability fields — Monthly Payment & Debt APR
                if accountType.isLiability {
                    Section("Debt Details") {
                        HStack {
                            TextField("Monthly Payment", text: $monthlyPaymentString)
                                .keyboardType(.decimalPad)
                            Text(currencyCode)
                                .foregroundStyle(.secondary)
                        }

                        if accountType == .loan {
                            HStack {
                                TextField("e.g. 5.5", text: $debtRateString)
                                    .keyboardType(.decimalPad)
                                Text("% APR")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("Enter the minimum monthly payment for this debt.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Color
                Section("Color") {
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
            }
            .navigationTitle(isEditing ? "Edit Account" : "New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") { save() }
                        .disabled(!isValid)
                        .bold()
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    // MARK: - Save

    private func save() {
        let rate = parseRate(rateString)
        let monthlyPayment = parseMinorUnits(monthlyPaymentString)
        let debtRate = parseRate(debtRateString)

        switch mode {
        case .create:
            service.createAccount(
                name: name,
                type: accountType,
                group: accountGroup,
                currencyCode: currencyCode,
                iconName: accountType.iconName,
                colorHex: selectedColorHex,
                annualInterestRate: accountType == .savings && rate > 0 ? rate : nil,
                expectedAnnualReturn: (accountType == .investment || accountType == .crypto) && rate > 0 ? rate : nil,
                benchmarkTicker: benchmarkTicker.isEmpty ? nil : benchmarkTicker,
                monthlyPayment: monthlyPayment,
                annualDebtInterestRate: accountType == .loan && debtRate > 0 ? debtRate : nil
            )

        case .edit(let account):
            account.name = name
            account.type = accountType.rawValue
            account.group = accountGroup.rawValue
            account.currencyCode = currencyCode
            account.iconName = accountType.iconName
            account.colorHex = selectedColorHex

            if accountType == .savings && rate > 0 {
                account.annualInterestRate = NSDecimalNumber(decimal: rate)
                account.expectedAnnualReturn = nil
            } else if (accountType == .investment || accountType == .crypto) && rate > 0 {
                account.expectedAnnualReturn = NSDecimalNumber(decimal: rate)
                account.annualInterestRate = nil
            } else {
                account.annualInterestRate = nil
                account.expectedAnnualReturn = nil
            }
            account.benchmarkTicker = benchmarkTicker.isEmpty ? nil : benchmarkTicker

            // Liability fields
            account.monthlyPaymentMinorUnits = monthlyPayment
            if accountType == .loan && debtRate > 0 {
                account.annualDebtInterestRate = NSDecimalNumber(decimal: debtRate)
            } else {
                account.annualDebtInterestRate = nil
            }

            service.updateAccount(account)
        }

        dismiss()
    }

    private func parseRate(_ string: String) -> Decimal {
        let cleaned = string.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value > 0 else { return 0 }
        return Decimal(value) / Decimal(100) // Convert percentage to decimal
    }

    private func parseMinorUnits(_ string: String) -> Int64 {
        let cleaned = string.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value > 0 else { return 0 }
        return Int64(value * 100)
    }
}

extension AccountEntity: @retroactive Identifiable {}

#Preview {
    NavigationStack {
        AccountsManagementView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
