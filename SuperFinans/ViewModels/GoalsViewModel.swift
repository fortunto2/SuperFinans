//
//  GoalsViewModel.swift
//  SuperFinans
//
//  ViewModel for the goals list tab.
//

import Foundation
import Combine

@MainActor
final class GoalsViewModel: ObservableObject {

    // MARK: - Published

    @Published var goals: [GoalEntity] = []
    @Published var showCreateGoal = false
    @Published var showPaywall = false
    @Published var celebratingMilestone: GoalMilestone?
    @Published var celebratingGoalName: String?

    // Quick deposit
    @Published var quickDepositGoal: GoalEntity?
    @Published var quickDepositAmount: String = ""

    // MARK: - Services

    private let goalService: GoalService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Premium

    var isPremium: Bool {
        PremiumManager.shared.isPremium
    }

    // MARK: - Summary Computed Properties

    var totalSaved: Money {
        let currency = goals.first?.currency ?? "USD"
        let total = goals.reduce(Int64(0)) { $0 + $1.currentAmountMinorUnits }
        return Money(minorUnits: total, currencyCode: currency)
    }

    var totalTarget: Money {
        let currency = goals.first?.currency ?? "USD"
        let total = goals.reduce(Int64(0)) { $0 + $1.targetAmountMinorUnits }
        return Money(minorUnits: total, currencyCode: currency)
    }

    var overallProgress: Double {
        let target = goals.reduce(Int64(0)) { $0 + $1.targetAmountMinorUnits }
        guard target > 0 else { return 0 }
        let current = goals.reduce(Int64(0)) { $0 + $1.currentAmountMinorUnits }
        return min(1.0, Double(current) / Double(target))
    }

    // MARK: - Init

    init(goalService: GoalService? = nil) {
        self.goalService = goalService ?? GoalService.shared
        setupObservers()
        loadGoals()
    }

    // MARK: - Load

    func loadGoals() {
        goals = goalService.fetchGoals()
    }

    // MARK: - Actions

    func requestCreateGoal() {
        if !isPremium && goalService.activeGoalCount() >= 1 {
            showPaywall = true
        } else {
            showCreateGoal = true
        }
    }

    func reorderGoals(from source: IndexSet, to destination: Int) {
        goals.move(fromOffsets: source, toOffset: destination)
        goalService.reorderGoals(goals)
    }

    func deleteGoal(at offsets: IndexSet) {
        for index in offsets {
            goalService.deleteGoal(goals[index])
        }
        loadGoals()
    }

    func archiveGoal(_ goal: GoalEntity) {
        goalService.archiveGoal(goal)
        loadGoals()
    }

    // MARK: - Quick Deposit

    func addQuickDeposit() {
        guard let goal = quickDepositGoal else { return }
        let cleaned = quickDepositAmount.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleaned), amount > 0 else { return }
        let minorUnits = Int64(amount * 100)

        goalService.addDeposit(to: goal, amount: minorUnits, note: "Quick deposit")
        FeatureDiscoveryFlags.shared.trackDeposit()

        quickDepositGoal = nil
        quickDepositAmount = ""
        loadGoals()
    }

    // MARK: - Template Creation

    func createFromTemplate(name: String, icon: String, color: String, amount: Int64) {
        if !isPremium && goalService.activeGoalCount() >= 1 {
            showPaywall = true
            return
        }

        goalService.createGoal(
            name: name,
            targetAmount: amount,
            iconName: icon,
            colorHex: color
        )
        FeatureDiscoveryFlags.shared.trackFirstGoal()
        loadGoals()
    }

    // MARK: - Observers

    private func setupObservers() {
        NotificationCenter.default.publisher(for: .goalCreated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadGoals() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .goalMilestoneReached)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let milestone = notification.userInfo?["milestone"] as? GoalMilestone,
                   let goalId = notification.userInfo?["goalId"] as? UUID {
                    self?.celebratingMilestone = milestone
                    self?.celebratingGoalName = self?.goals.first { $0.id == goalId }?.displayName
                }
            }
            .store(in: &cancellables)
    }

    func dismissMilestone() {
        celebratingMilestone = nil
        celebratingGoalName = nil
    }
}
