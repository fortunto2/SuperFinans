//
//  PortfolioViewModel.swift
//  SuperFinans
//
//  ViewModel for the Portfolio dashboard — aggregates accounts by group,
//  computes net worth, and loads milestones.
//

import Foundation
import Combine

@MainActor
final class PortfolioViewModel: ObservableObject {

    // MARK: - Published

    @Published var personalAccounts: [AccountEntity] = []
    @Published var businessAccounts: [AccountEntity] = []
    @Published var milestones: [GoalEntity] = []

    // Quick deposit for milestones
    @Published var quickDepositGoal: GoalEntity?
    @Published var quickDepositAmount: String = ""

    // Sheets
    @Published var showCreateAccount = false
    @Published var showCreateGoal = false
    @Published var showPaywall = false

    // Milestone celebrations
    @Published var celebratingMilestone: GoalMilestone?
    @Published var celebratingGoalName: String?

    // MARK: - Services

    private let accountService: AccountService
    private let goalService: GoalService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed

    var allAccounts: [AccountEntity] {
        personalAccounts + businessAccounts
    }

    /// Net worth = sum of all account balances (in base currency, simplified for now)
    var netWorth: Int64 {
        allAccounts.reduce(Int64(0)) { $0 + $1.balanceMinorUnits }
    }

    var netWorthMoney: Money {
        Money(minorUnits: netWorth, currencyCode: baseCurrency)
    }

    var personalTotal: Money {
        let total = personalAccounts.reduce(Int64(0)) { $0 + $1.balanceMinorUnits }
        return Money(minorUnits: total, currencyCode: baseCurrency)
    }

    var businessTotal: Money {
        let total = businessAccounts.reduce(Int64(0)) { $0 + $1.balanceMinorUnits }
        return Money(minorUnits: total, currencyCode: baseCurrency)
    }

    var baseCurrency: String {
        UserDefaults.standard.string(forKey: "superfinans.currency_code") ?? "USD"
    }

    var isPremium: Bool {
        PremiumManager.shared.isPremium
    }

    // Milestones summary
    var milestonesProgress: Double {
        let target = milestones.reduce(Int64(0)) { $0 + $1.targetAmountMinorUnits }
        guard target > 0 else { return 0 }
        let current = milestones.reduce(Int64(0)) { $0 + $1.currentAmountMinorUnits }
        return min(1.0, Double(current) / Double(target))
    }

    // MARK: - Init

    init(accountService: AccountService? = nil, goalService: GoalService? = nil) {
        self.accountService = accountService ?? AccountService.shared
        self.goalService = goalService ?? GoalService.shared
        setupObservers()
        loadAll()
    }

    // MARK: - Load

    func loadAll() {
        let accounts = accountService.fetchAccounts()
        personalAccounts = accounts.filter { $0.accountGroup == .personal }
        businessAccounts = accounts.filter { $0.accountGroup == .business }
        milestones = goalService.fetchGoals()
    }

    // MARK: - Milestone Actions

    func requestCreateGoal() {
        if !isPremium && goalService.activeGoalCount() >= 1 {
            showPaywall = true
        } else {
            showCreateGoal = true
        }
    }

    func deleteGoal(at offsets: IndexSet) {
        for index in offsets {
            goalService.deleteGoal(milestones[index])
        }
        loadAll()
    }

    func addQuickDeposit() {
        guard let goal = quickDepositGoal else { return }
        let cleaned = quickDepositAmount.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleaned), amount > 0 else { return }
        let minorUnits = Int64(amount * 100)

        goalService.addDeposit(to: goal, amount: minorUnits, note: "Quick deposit")
        FeatureDiscoveryFlags.shared.trackDeposit()

        quickDepositGoal = nil
        quickDepositAmount = ""
        loadAll()
    }

    // MARK: - Observers

    private func setupObservers() {
        NotificationCenter.default.publisher(for: .goalCreated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadAll() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .goalMilestoneReached)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let milestone = notification.userInfo?["milestone"] as? GoalMilestone,
                   let goalId = notification.userInfo?["goalId"] as? UUID {
                    self?.celebratingMilestone = milestone
                    self?.celebratingGoalName = self?.milestones.first { $0.id == goalId }?.displayName
                }
            }
            .store(in: &cancellables)
    }

    func dismissMilestone() {
        celebratingMilestone = nil
        celebratingGoalName = nil
    }
}
