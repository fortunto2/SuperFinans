//
//  ExportService.swift
//  SuperFinans
//
//  JSON export of all user data.
//

import Foundation

@MainActor
final class ExportService {

    static let shared = ExportService()
    private init() {}

    struct ExportData: Codable {
        let exportDate: Date
        let version: String
        let accounts: [ExportAccount]
        let goals: [ExportGoal]
        let transactions: [ExportTransaction]
    }

    struct ExportAccount: Codable {
        let id: String
        let name: String
        let type: String
        let currencyCode: String
        let balanceMinorUnits: Int64
    }

    struct ExportGoal: Codable {
        let id: String
        let name: String
        let targetAmountMinorUnits: Int64
        let currentAmountMinorUnits: Int64
        let currencyCode: String
        let targetDate: Date?
        let annualInterestRate: Double
        let monthlyContributionMinorUnits: Int64
    }

    struct ExportTransaction: Codable {
        let id: String
        let amountMinorUnits: Int64
        let currencyCode: String
        let categoryId: String?
        let note: String?
        let date: Date
        let accountName: String?
        let goalName: String?
    }

    func exportJSON() -> Data? {
        let accounts = AccountService.shared.fetchAccounts()
        let goals = GoalService.shared.fetchGoals()
        let transactions = TransactionService.shared.fetchTransactions()

        let exportData = ExportData(
            exportDate: Date(),
            version: "1.0",
            accounts: accounts.map { account in
                ExportAccount(
                    id: account.id?.uuidString ?? "",
                    name: account.displayName,
                    type: account.type ?? "checking",
                    currencyCode: account.currency,
                    balanceMinorUnits: account.balanceMinorUnits
                )
            },
            goals: goals.map { goal in
                ExportGoal(
                    id: goal.id?.uuidString ?? "",
                    name: goal.displayName,
                    targetAmountMinorUnits: goal.targetAmountMinorUnits,
                    currentAmountMinorUnits: goal.currentAmountMinorUnits,
                    currencyCode: goal.currency,
                    targetDate: goal.targetDate,
                    annualInterestRate: goal.interestRate.doubleValue,
                    monthlyContributionMinorUnits: goal.monthlyContributionMinorUnits
                )
            },
            transactions: transactions.map { tx in
                ExportTransaction(
                    id: tx.id?.uuidString ?? "",
                    amountMinorUnits: tx.amountMinorUnits,
                    currencyCode: tx.currencyCode ?? "USD",
                    categoryId: tx.categoryId,
                    note: tx.note,
                    date: tx.transactionDate,
                    accountName: tx.account?.displayName,
                    goalName: tx.goal?.displayName
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(exportData)
    }

    // MARK: - CSV

    /// Transactions as a spreadsheet. JSON is the honest archive format and stays
    /// free; this is the one people actually open in Numbers or Excel.
    func exportTransactionsCSV() -> Data? {
        let transactions = TransactionService.shared.fetchTransactions()
        var rows = ["date,account,category,note,amount,currency"]

        for tx in transactions {
            let money = Money(minorUnits: tx.amountMinorUnits,
                              currencyCode: tx.account?.currency ?? "USD")
            rows.append([
                Self.csvField(tx.date?.iso8601Day ?? ""),
                Self.csvField(tx.account?.displayName ?? ""),
                Self.csvField(tx.categoryId ?? ""),
                Self.csvField(tx.note ?? ""),
                NSDecimalNumber(decimal: money.decimalAmount).stringValue,
                Self.csvField(money.currencyCode),
            ].joined(separator: ","))
        }
        return rows.joined(separator: "\n").data(using: .utf8)
    }

    /// Quotes only when needed, and doubles any quote inside — the two rules that
    /// separate a CSV that opens cleanly from one that shifts every column.
    private static func csvField(_ value: String) -> String {
        guard value.contains(where: { ",\"\n".contains($0) }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    func exportCSVFileURL() -> URL? {
        guard let data = exportTransactionsCSV() else { return nil }
        let fileName = "SuperFinans_Transactions_\(Date().dateGroupKey).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return url
        } catch {
            print("ExportService: Failed to write CSV: \(error)")
            return nil
        }
    }

    func exportFileURL() -> URL? {
        guard let data = exportJSON() else { return nil }
        let fileName = "SuperFinans_Export_\(Date().dateGroupKey).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("ExportService: Failed to write export: \(error)")
            return nil
        }
    }
}
