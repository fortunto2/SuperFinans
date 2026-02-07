//
//  DashboardViewModel.swift
//  SuperFinans
//
//  ViewModel for the Dashboard — Freedom Ratio, Net Worth, Monthly Snapshot,
//  Time to Freedom, Passive Income Breakdown.
//

import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - Published

    @Published var freedomRatio: Decimal = 0
    @Published var netWorth: Money = .zero()

    @Published var monthlyIncome: Money = .zero()
    @Published var monthlyExpenses: Money = .zero()
    @Published var monthlySurplus: Money = .zero()
    @Published var monthlyPassiveIncome: Money = .zero()

    @Published var monthsToFreedom: Int?
    @Published var freedomProjection: [FreedomProjectionPoint] = []
    @Published var passiveIncomeBreakdown: [(account: AccountEntity, income: Money)] = []

    @Published var milestones: [GoalEntity] = []

    // Sheets
    @Published var showAddTransaction = false
    @Published var showCreateAccount = false
    @Published var showPaywall = false

    // MARK: - Services

    private let cashFlowService: CashFlowService
    private let goalService: GoalService
    private var cancellables = Set<AnyCancellable>()

    var baseCurrency: String {
        UserDefaults.standard.string(forKey: "superfinans.currency_code") ?? "USD"
    }

    var isPremium: Bool {
        PremiumManager.shared.isPremium
    }

    // MARK: - Init

    init(
        cashFlowService: CashFlowService? = nil,
        goalService: GoalService? = nil
    ) {
        self.cashFlowService = cashFlowService ?? CashFlowService.shared
        self.goalService = goalService ?? GoalService.shared
        setupObservers()
        loadAll()
    }

    // MARK: - Load

    func loadAll() {
        let currency = baseCurrency
        let now = Date()

        // Net worth
        let nw = cashFlowService.netWorth()
        netWorth = Money(minorUnits: nw, currencyCode: currency)

        // Monthly income & expenses
        let active = cashFlowService.activeIncome(for: now)
        let passive = cashFlowService.totalMonthlyPassiveIncome()
        let expenses = cashFlowService.totalExpenses(for: now)
        let totalIncome = active + passive

        monthlyIncome = Money(minorUnits: totalIncome, currencyCode: currency)
        monthlyExpenses = Money(minorUnits: expenses, currencyCode: currency)
        monthlySurplus = Money(minorUnits: totalIncome - expenses, currencyCode: currency)
        monthlyPassiveIncome = Money(minorUnits: passive, currencyCode: currency)

        // Freedom ratio
        freedomRatio = cashFlowService.freedomRatio(for: now)

        // Time to freedom
        monthsToFreedom = cashFlowService.monthsToFreedom(for: now)

        // Passive income breakdown
        let assets = cashFlowService.fetchAssets()
        passiveIncomeBreakdown = assets
            .filter { $0.monthlyPassiveIncome.minorUnits > 0 }
            .sorted { $0.monthlyPassiveIncome.minorUnits > $1.monthlyPassiveIncome.minorUnits }
            .map { (account: $0, income: $0.monthlyPassiveIncome) }

        // Freedom projection
        let investedAssets = assets
            .filter { $0.accountType == .investment || $0.accountType == .crypto || $0.accountType == .company }
            .reduce(Int64(0)) { $0 + $1.balanceMinorUnits }

        let surplus = totalIncome - expenses
        freedomProjection = FinancialCalculator.shared.freedomProjectionPoints(
            currentInvestedAssets: investedAssets,
            monthlyExpenses: expenses,
            monthlySurplus: surplus,
            averageAnnualReturn: cashFlowService.weightedAverageReturn()
        )

        // Milestones
        milestones = goalService.fetchGoals()
    }

    // MARK: - Observers

    private func setupObservers() {
        NotificationCenter.default.publisher(for: .goalCreated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadAll() }
            .store(in: &cancellables)
    }
}
