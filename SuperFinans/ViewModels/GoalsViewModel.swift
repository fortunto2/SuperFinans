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

    // MARK: - Services

    private let goalService: GoalService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Premium

    var isPremium: Bool {
        PremiumManager.shared.isPremium
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
