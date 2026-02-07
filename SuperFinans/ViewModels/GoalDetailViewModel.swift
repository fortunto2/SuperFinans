//
//  GoalDetailViewModel.swift
//  SuperFinans
//
//  ViewModel for individual goal detail view.
//

import Foundation

@MainActor
final class GoalDetailViewModel: ObservableObject {

    // MARK: - Published

    @Published var goal: GoalEntity
    @Published var projectionPoints: [GoalProjectionPoint] = []
    @Published var whatIfContribution: Double = 0
    @Published var whatIfTargetDate: Date?
    @Published var showAddDeposit = false
    @Published var depositAmount: String = ""
    @Published var depositNote: String = ""
    @Published var showEditGoal = false

    // MARK: - Services

    private let goalService: GoalService
    private let calculator: FinancialCalculator

    // MARK: - Computed

    var progressPercentage: Double {
        goal.progressPercentage
    }

    var requiredMonthly: Money {
        guard let months = goal.monthsRemaining, months > 0 else {
            return Money.zero(currencyCode: goal.currency)
        }
        let required = calculator.requiredMonthlyContribution(
            targetAmount: goal.targetAmountMinorUnits,
            currentAmount: goal.currentAmountMinorUnits,
            annualRate: goal.interestRate,
            months: months
        )
        return Money(minorUnits: required, currencyCode: goal.currency)
    }

    var monthsToGoalAtCurrentRate: Int? {
        calculator.monthsToGoal(
            targetAmount: goal.targetAmountMinorUnits,
            currentAmount: goal.currentAmountMinorUnits,
            monthlyContribution: goal.monthlyContributionMinorUnits,
            annualRate: goal.interestRate
        )
    }

    var whatIfMonthlyContribution: Int64 {
        Int64(whatIfContribution * 100) // Convert dollars to cents
    }

    // MARK: - Init

    init(goal: GoalEntity, goalService: GoalService? = nil, calculator: FinancialCalculator? = nil) {
        self.goal = goal
        self.goalService = goalService ?? GoalService.shared
        self.calculator = calculator ?? FinancialCalculator.shared
        self.whatIfContribution = Double(goal.monthlyContributionMinorUnits) / 100.0
        updateProjection()
    }

    // MARK: - Projection

    func updateProjection() {
        let months = goal.monthsRemaining ?? 60 // Default 5 years
        let contribution = whatIfMonthlyContribution > 0
            ? whatIfMonthlyContribution
            : goal.monthlyContributionMinorUnits

        projectionPoints = calculator.projectionPoints(
            currentAmount: goal.currentAmountMinorUnits,
            monthlyContribution: contribution,
            annualRate: goal.interestRate,
            months: max(months, 1),
            currencyCode: goal.currency
        )

        // Calculate what-if target date
        if let months = calculator.monthsToGoal(
            targetAmount: goal.targetAmountMinorUnits,
            currentAmount: goal.currentAmountMinorUnits,
            monthlyContribution: contribution,
            annualRate: goal.interestRate
        ) {
            whatIfTargetDate = Date().addingMonths(months)
        } else {
            whatIfTargetDate = nil
        }
    }

    // MARK: - Deposit

    func addDeposit() {
        let amountString = depositAmount.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(amountString), amount > 0 else { return }
        let minorUnits = Int64(amount * 100)

        goalService.addDeposit(
            to: goal,
            amount: minorUnits,
            note: depositNote.isEmpty ? nil : depositNote
        )
        FeatureDiscoveryFlags.shared.trackDeposit()

        depositAmount = ""
        depositNote = ""
        showAddDeposit = false
        updateProjection()
    }

    func withdraw(amount: Int64, note: String?) {
        goalService.addDeposit(to: goal, amount: -amount, note: note)
        updateProjection()
    }

    // MARK: - Update

    func updateContribution() {
        goal.monthlyContributionMinorUnits = whatIfMonthlyContribution
        goalService.updateGoal(goal)
        updateProjection()
    }

    // MARK: - Refresh

    func refreshGoal() {
        if let id = goal.id, let refreshed = goalService.fetchGoal(id: id) {
            goal = refreshed
        }
        updateProjection()
    }
}
