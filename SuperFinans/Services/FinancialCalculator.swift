//
//  FinancialCalculator.swift
//  SuperFinans
//
//  Financial calculations using Decimal for precision.
//  Compound interest, monthly contributions, projections.
//

import Foundation

@MainActor
final class FinancialCalculator {

    static let shared = FinancialCalculator()
    private init() {}

    // MARK: - Compound Interest

    /// Calculate future value with compound interest
    /// FV = PV × (1 + r/n)^(n×t) + PMT × [((1 + r/n)^(n×t) - 1) / (r/n)]
    /// - Parameters:
    ///   - principal: Current amount (minor units)
    ///   - monthlyContribution: Monthly contribution (minor units)
    ///   - annualRate: Annual interest rate as decimal (e.g., 0.07 for 7%)
    ///   - compounding: Compounding frequency
    ///   - months: Number of months
    /// - Returns: Future value in minor units
    func futureValue(
        principal: Int64,
        monthlyContribution: Int64,
        annualRate: Decimal,
        compounding: CompoundingFrequency,
        months: Int
    ) -> Int64 {
        let pv = Decimal(principal)
        let pmt = Decimal(monthlyContribution)

        guard annualRate > 0 else {
            // Simple addition without interest
            let result = pv + pmt * Decimal(months)
            return NSDecimalNumber(decimal: result.rounded(scale: 0)).int64Value
        }

        let n = Decimal(compounding.periodsPerYear)
        let r = annualRate / n
        let t = Decimal(months) / Decimal(12)
        let nt = n * t
        let ntInt = NSDecimalNumber(decimal: nt).intValue

        // (1 + r/n)^(n*t)
        let growthFactor = (Decimal(1) + r).power(ntInt)

        // PV * growthFactor
        let principalFV = pv * growthFactor

        // PMT contribution: we need monthly-to-period conversion
        // PMT × [(growthFactor - 1) / r] × (compounding periods factor)
        let monthlyPeriods = Decimal(months)
        let monthlyRate = annualRate / Decimal(12)

        let monthlyGrowthFactor: Decimal
        if monthlyRate > 0 {
            monthlyGrowthFactor = (Decimal(1) + monthlyRate).power(months)
        } else {
            monthlyGrowthFactor = Decimal(1)
        }

        let contributionFV: Decimal
        if monthlyRate > 0 {
            contributionFV = pmt * ((monthlyGrowthFactor - Decimal(1)) / monthlyRate)
        } else {
            contributionFV = pmt * monthlyPeriods
        }

        let total = principalFV + contributionFV
        return NSDecimalNumber(decimal: total.rounded(scale: 0)).int64Value
    }

    // MARK: - Required Monthly Contribution

    /// Calculate how much to save per month to reach a goal
    /// PMT = (FV - PV × (1+r)^n) × r / ((1+r)^n - 1)
    func requiredMonthlyContribution(
        targetAmount: Int64,
        currentAmount: Int64,
        annualRate: Decimal,
        months: Int
    ) -> Int64 {
        guard months > 0 else { return 0 }

        let fv = Decimal(targetAmount)
        let pv = Decimal(currentAmount)

        guard annualRate > 0 else {
            let remaining = fv - pv
            let monthly = remaining / Decimal(months)
            return max(0, NSDecimalNumber(decimal: monthly.rounded(scale: 0)).int64Value)
        }

        let r = annualRate / Decimal(12) // monthly rate
        let growthFactor = (Decimal(1) + r).power(months)
        let principalGrowth = pv * growthFactor

        let numerator = (fv - principalGrowth) * r
        let denominator = growthFactor - Decimal(1)

        guard denominator != 0 else {
            return max(0, NSDecimalNumber(decimal: ((fv - pv) / Decimal(months)).rounded(scale: 0)).int64Value)
        }

        let pmt = numerator / denominator
        return max(0, NSDecimalNumber(decimal: pmt.rounded(scale: 0)).int64Value)
    }

    // MARK: - Months to Goal

    /// Calculate how many months to reach a goal with given monthly contribution
    func monthsToGoal(
        targetAmount: Int64,
        currentAmount: Int64,
        monthlyContribution: Int64,
        annualRate: Decimal
    ) -> Int? {
        guard monthlyContribution > 0 else { return nil }
        guard targetAmount > currentAmount else { return 0 }

        // Iterative approach for accuracy
        var accumulated = Decimal(currentAmount)
        let target = Decimal(targetAmount)
        let pmt = Decimal(monthlyContribution)
        let monthlyRate = annualRate / Decimal(12)

        for month in 1...600 { // Max 50 years
            accumulated = accumulated * (Decimal(1) + monthlyRate) + pmt
            if accumulated >= target {
                return month
            }
        }

        return nil
    }

    // MARK: - Projection Points

    /// Generate monthly projection points for a goal (for charts)
    func projectionPoints(
        currentAmount: Int64,
        monthlyContribution: Int64,
        annualRate: Decimal,
        months: Int,
        currencyCode: String
    ) -> [GoalProjectionPoint] {
        var points: [GoalProjectionPoint] = []
        let monthlyRate = annualRate / Decimal(12)
        var projectedWithInterest = Decimal(currentAmount)
        var contributionOnly = Decimal(currentAmount)
        let pmt = Decimal(monthlyContribution)
        let now = Date()

        // Add starting point
        points.append(GoalProjectionPoint(
            date: now,
            projectedAmount: projectedWithInterest,
            contributionOnly: contributionOnly
        ))

        let step = max(1, months / 24) // Limit to ~24 data points

        for month in 1...months {
            projectedWithInterest = projectedWithInterest * (Decimal(1) + monthlyRate) + pmt
            contributionOnly = contributionOnly + pmt

            if month % step == 0 || month == months {
                let date = now.addingMonths(month)
                points.append(GoalProjectionPoint(
                    date: date,
                    projectedAmount: projectedWithInterest.rounded(scale: 0),
                    contributionOnly: contributionOnly.rounded(scale: 0)
                ))
            }
        }

        return points
    }

    // MARK: - Goal Progress

    /// Calculate percentage progress toward a goal
    func progressPercentage(current: Int64, target: Int64) -> Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(current) / Double(target))
    }

    // MARK: - Freedom Calculations

    /// Calculate months until financial freedom (passive income >= expenses)
    /// - Parameters:
    ///   - currentInvestedAssets: Total invested assets in minor units
    ///   - monthlyExpenses: Monthly expenses in minor units
    ///   - monthlySurplus: Monthly surplus (income - expenses) in minor units
    ///   - averageAnnualReturn: Weighted average annual return as decimal (e.g. 0.08)
    /// - Returns: Number of months until freedom, or nil if > 600 months
    func monthsToFreedom(
        currentInvestedAssets: Int64,
        monthlyExpenses: Int64,
        monthlySurplus: Int64,
        averageAnnualReturn: Decimal
    ) -> Int? {
        // Delegates to FreedomEngine so there is one compounding loop in the
        // app, not two that have to be fixed in parallel. Kept as a method
        // because CashFlowService and DashboardViewModel call it by this name.
        FreedomEngine.monthsToFreedom(
            assets: currentInvestedAssets,
            monthlyExpenses: monthlyExpenses,
            monthlySurplus: monthlySurplus,
            monthlyRate: averageAnnualReturn / Decimal(12)
        )
    }

    /// Generate projection points for freedom chart
    func freedomProjectionPoints(
        currentInvestedAssets: Int64,
        monthlyExpenses: Int64,
        monthlySurplus: Int64,
        averageAnnualReturn: Decimal,
        maxMonths: Int = 360
    ) -> [FreedomProjectionPoint] {
        var points: [FreedomProjectionPoint] = []
        let monthlyRate = averageAnnualReturn / Decimal(12)
        var assets = Decimal(currentInvestedAssets)
        let expenses = Decimal(monthlyExpenses)
        let surplus = Decimal(monthlySurplus)
        let now = Date()

        // Starting point
        let startPassive = assets * monthlyRate
        let startRatio = expenses > 0 ? startPassive / expenses : 0
        points.append(FreedomProjectionPoint(
            month: 0,
            date: now,
            passiveIncome: startPassive.rounded(scale: 0),
            totalInvestedAssets: assets.rounded(scale: 0),
            expenses: expenses.rounded(scale: 0),
            freedomRatio: startRatio
        ))

        let step = max(1, maxMonths / 36)

        for month in 1...maxMonths {
            assets = assets * (Decimal(1) + monthlyRate) + surplus
            let passiveIncome = assets * monthlyRate
            let ratio = expenses > 0 ? passiveIncome / expenses : 0

            if month % step == 0 || month == maxMonths || ratio >= 1 {
                points.append(FreedomProjectionPoint(
                    month: month,
                    date: now.addingMonths(month),
                    passiveIncome: passiveIncome.rounded(scale: 0),
                    totalInvestedAssets: assets.rounded(scale: 0),
                    expenses: expenses.rounded(scale: 0),
                    freedomRatio: ratio
                ))
            }

            if ratio >= 1 { break }
        }

        return points
    }
}
