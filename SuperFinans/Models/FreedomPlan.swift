//
//  FreedomPlan.swift
//  SuperFinans
//
//  The three numbers a person can answer in under a minute, and the one
//  number they get back: the year they stop needing a salary.
//
//  Accounts and transactions refine this later. They are not required to
//  get an answer, which is the whole point — every competitor demands a
//  month of bookkeeping before it tells you anything.
//

import Foundation

struct FreedomPlan: Codable, Equatable, Sendable {

    /// What life costs per month, in minor units.
    var monthlyExpensesMinor: Int64
    /// What is already invested, in minor units.
    var currentSavingsMinor: Int64
    /// What gets added every month, in minor units.
    var monthlySavingsMinor: Int64
    /// Year of birth. Optional — without it we show a year, not an age.
    var birthYear: Int?
    /// Expected long-run annual return, as a percentage (7 = 7%).
    var annualReturnPercent: Double
    /// ISO 4217 code the three numbers are expressed in.
    var currencyCode: String
    /// Known changes to what life will cost. Every other calculator treats
    /// monthly spending as a constant for thirty years, which nobody's life is.
    var shifts: [ExpenseShift]
    /// Optional second currency shown alongside every amount. People who earn
    /// in a soft currency still think in dollars, and the horizon here is long
    /// enough that they are right to.
    var displayCurrencyCode: String?

    static let defaultReturnPercent: Double = 7.0

    static func empty(currencyCode: String) -> FreedomPlan {
        FreedomPlan(
            monthlyExpensesMinor: 0,
            currentSavingsMinor: 0,
            monthlySavingsMinor: 0,
            birthYear: nil,
            annualReturnPercent: defaultReturnPercent,
            currencyCode: currencyCode,
            shifts: [],
            displayCurrencyCode: nil
        )
    }

    /// A plan is usable the moment we know what life costs.
    var isConfigured: Bool { monthlyExpensesMinor > 0 }

}

// MARK: - Expense shifts

/// A dated step change in monthly spending: children leave, a mortgage ends, a
/// state pension starts. Expressed as a percentage because that is how people
/// know it ("the kids are about a third of what we spend").
struct ExpenseShift: Codable, Equatable, Identifiable, Sendable {

    var id: UUID
    /// Calendar year the change takes effect.
    var year: Int
    /// Signed percentage applied to the ORIGINAL monthly figure. -30 means
    /// spending drops by thirty percent of what it is today.
    var percent: Int
    var label: String

    init(id: UUID = UUID(), year: Int, percent: Int, label: String) {
        self.id = id
        self.year = year
        self.percent = percent
        self.label = label
    }

    /// The presets that cover most of what people actually know about.
    static func presets(currentYear: Int) -> [ExpenseShift] {
        [
            ExpenseShift(year: currentYear + 10, percent: -25, label: "Children move out"),
            ExpenseShift(year: currentYear + 15, percent: -30, label: "Mortgage paid off"),
            ExpenseShift(year: currentYear + 20, percent: -15, label: "State pension starts"),
        ]
    }
}

// MARK: - Outcome

struct FreedomOutcome: Equatable, Sendable {

    /// Months from today until passive income covers expenses. Nil = beyond 50 years.
    let months: Int?
    /// Calendar year freedom lands in, if it lands.
    let year: Int?
    /// Age in that year, when the birth year is known.
    let age: Int?
    /// Invested assets needed for passive income to cover expenses.
    let targetAssetsMinor: Int64
    /// Share of expenses currently covered by passive income, 0…1.
    let currentRatio: Double

    var isReachable: Bool { months != nil }

    /// Whole years, rounded down — "15 years" reads better than "179 months".
    var years: Int? { months.map { $0 / 12 } }
    var remainderMonths: Int? { months.map { $0 % 12 } }
}

// MARK: - Calculation

enum FreedomEngine {

    /// The horizon we refuse to project past. Beyond this the arithmetic is
    /// honest but the answer is useless.
    static let maxMonths = 600

    static func outcome(for plan: FreedomPlan, extraMonthlyMinor: Int64 = 0) -> FreedomOutcome {
        let annualReturn = Decimal(plan.annualReturnPercent) / Decimal(100)
        let monthlyRate = annualReturn / Decimal(12)
        let expenses = plan.monthlyExpensesMinor
        let surplus = plan.monthlySavingsMinor + extraMonthlyMinor

        // Assets whose monthly yield equals monthly expenses.
        // Round before converting: NSDecimalNumber.int64Value returns 0 for a
        // Decimal with ~39 significant digits, which a division by a monthly
        // rate always produces.
        let target: Int64 = monthlyRate > 0
            ? NSDecimalNumber(decimal: (Decimal(expenses) / monthlyRate).rounded(scale: 0)).int64Value
            : 0

        let passiveNow = NSDecimalNumber(
            decimal: Decimal(plan.currentSavingsMinor) * monthlyRate
        ).doubleValue
        let ratio = expenses > 0 ? min(passiveNow / Double(expenses), 1.0) : 0

        let months = monthsToFreedom(
            assets: plan.currentSavingsMinor,
            monthlyExpenses: expenses,
            monthlySurplus: surplus,
            monthlyRate: monthlyRate,
            shifts: plan.shifts
        )

        var year: Int?
        var age: Int?
        if let months {
            let date = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
            let y = Calendar.current.component(.year, from: date)
            year = y
            age = plan.birthYear.map { y - $0 }
        }

        return FreedomOutcome(
            months: months,
            year: year,
            age: age,
            targetAssetsMinor: target,
            currentRatio: ratio
        )
    }

    /// Compound the pot month by month until its yield covers a month of life.
    /// Deliberately a loop and not a closed form: the loop stays correct when
    /// contributions or expenses become time-varying, which is the next feature.
    static func monthsToFreedom(
        assets: Int64,
        monthlyExpenses: Int64,
        monthlySurplus: Int64,
        monthlyRate: Decimal,
        shifts: [ExpenseShift] = []
    ) -> Int? {
        // Zero expenses is missing data, not freedom.
        guard monthlyExpenses > 0, monthlyRate > 0 else { return nil }
        guard monthlySurplus > 0 || assets > 0 else { return nil }

        var pot = Decimal(assets)
        let surplus = Decimal(monthlySurplus)
        let thisYear = Calendar.current.component(.year, from: Date())

        for month in 1...maxMonths {
            pot = pot * (Decimal(1) + monthlyRate) + surplus
            let need = expenses(base: monthlyExpenses, shifts: shifts,
                                monthsFromNow: month, startYear: thisYear)
            if pot * monthlyRate >= need { return month }
        }
        return nil
    }

    /// Monthly spending `monthsFromNow` months out, with every shift that has
    /// taken effect by then applied to the original figure.
    static func expenses(
        base: Int64,
        shifts: [ExpenseShift],
        monthsFromNow: Int,
        startYear: Int
    ) -> Decimal {
        guard !shifts.isEmpty else { return Decimal(base) }
        let year = startYear + monthsFromNow / 12
        let applied = shifts.filter { $0.year <= year }.reduce(0) { $0 + $1.percent }
        // A floor of 10%: no sequence of life events reduces living costs to zero.
        let factor = max(10, 100 + applied)
        return Decimal(base) * Decimal(factor) / Decimal(100)
    }

    /// How many months earlier freedom arrives if you add `extraMonthlyMinor`
    /// every month. Nil when either scenario runs past the horizon.
    static func monthsSaved(for plan: FreedomPlan, extraMonthlyMinor: Int64) -> Int? {
        guard extraMonthlyMinor != 0 else { return 0 }
        guard let base = outcome(for: plan).months,
              let boosted = outcome(for: plan, extraMonthlyMinor: extraMonthlyMinor).months
        else { return nil }
        return base - boosted
    }
}

// MARK: - Shared storage

enum FreedomPlanStorage {

    /// App Group so the widget reads what the app writes. Falls back to the
    /// app's own defaults when the group is unavailable (e.g. unsigned build).
    static let appGroup = "group.co.superduperai.SuperFinans"
    static let key = "superfinans.freedom_plan"
    static let currencyKey = "superfinans.currency_code"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    /// Decode without any UI dependency — this is what the widget calls.
    static func loadPlan() -> FreedomPlan? {
        guard let data = defaults.data(forKey: key),
              let plan = try? JSONDecoder().decode(FreedomPlan.self, from: data)
        else { return nil }
        return plan.isConfigured ? plan : nil
    }
}
