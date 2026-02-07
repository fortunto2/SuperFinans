//
//  BalanceSheetViewModel.swift
//  SuperFinans
//
//  ViewModel for the Balance Sheet tab — Assets grouped, Liabilities grouped,
//  Net Worth.
//

import Foundation
import Combine

@MainActor
final class BalanceSheetViewModel: ObservableObject {

    // MARK: - Published

    @Published var assetGroups: [CashFlowService.AccountGroupSection] = []
    @Published var liabilityGroups: [CashFlowService.AccountGroupSection] = []

    @Published var totalAssets: Money = .zero()
    @Published var totalLiabilities: Money = .zero()
    @Published var netWorth: Money = .zero()

    @Published var showCreateAccount = false

    // MARK: - Services

    private let cashFlowService: CashFlowService

    var baseCurrency: String {
        UserDefaults.standard.string(forKey: "superfinans.currency_code") ?? "USD"
    }

    // MARK: - Init

    init(cashFlowService: CashFlowService? = nil) {
        self.cashFlowService = cashFlowService ?? CashFlowService.shared
        loadData()
    }

    // MARK: - Load

    func loadData() {
        let currency = baseCurrency

        assetGroups = cashFlowService.assetsGrouped()
        liabilityGroups = cashFlowService.liabilitiesGrouped()

        let assets = cashFlowService.totalAssets()
        let liabilities = cashFlowService.totalLiabilities()

        totalAssets = Money(minorUnits: assets, currencyCode: currency)
        totalLiabilities = Money(minorUnits: liabilities, currencyCode: currency)
        netWorth = Money(minorUnits: cashFlowService.netWorth(), currencyCode: currency)
    }
}
