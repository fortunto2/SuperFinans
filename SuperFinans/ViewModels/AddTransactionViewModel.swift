//
//  AddTransactionViewModel.swift
//  SuperFinans
//
//  ViewModel for the add transaction sheet.
//

import Foundation

@MainActor
final class AddTransactionViewModel: ObservableObject {

    // MARK: - Published

    @Published var amountString: String = ""
    @Published var selectedCategory: CategoryDefinition = .other
    @Published var note: String = ""
    @Published var date: Date = Date()
    @Published var isExpense: Bool = true
    @Published var selectedAccount: AccountEntity?

    // MARK: - Services

    private let transactionService: TransactionService
    private let accountService: AccountService

    // MARK: - Computed

    var accounts: [AccountEntity] {
        accountService.fetchAccounts()
    }

    var amountMinorUnits: Int64 {
        let cleaned = amountString.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleaned), amount > 0 else { return 0 }
        let minorUnits = Int64(amount * 100)
        return isExpense ? -minorUnits : minorUnits
    }

    var isValid: Bool {
        amountMinorUnits != 0
    }

    // MARK: - Init

    init(transactionService: TransactionService? = nil, accountService: AccountService? = nil) {
        self.transactionService = transactionService ?? TransactionService.shared
        self.accountService = accountService ?? AccountService.shared
        self.selectedAccount = accounts.first
    }

    // MARK: - Actions

    func save() {
        guard isValid else { return }

        transactionService.createTransaction(
            amount: amountMinorUnits,
            currencyCode: selectedAccount?.currency ?? "USD",
            categoryId: selectedCategory.rawValue,
            note: note.isEmpty ? nil : note,
            date: date,
            account: selectedAccount
        )

        reset()
    }

    func appendDigit(_ digit: String) {
        // Prevent multiple dots
        if digit == "." && amountString.contains(".") { return }
        // Limit decimal places to 2
        if let dotIndex = amountString.firstIndex(of: ".") {
            let decimals = amountString[amountString.index(after: dotIndex)...]
            if decimals.count >= 2 { return }
        }
        amountString += digit
    }

    func deleteLastDigit() {
        guard !amountString.isEmpty else { return }
        amountString.removeLast()
    }

    func clearAmount() {
        amountString = ""
    }

    private func reset() {
        amountString = ""
        selectedCategory = .other
        note = ""
        date = Date()
    }
}
