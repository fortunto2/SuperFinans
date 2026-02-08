//
//  SuperFinansLogicTests.swift
//  SuperFinansTests
//
//  Tests for the full data pipeline:
//  Money → TransactionEntity → TransactionService → CashFlowService → DashboardViewModel
//

import XCTest
@testable import SuperFinans

@MainActor
final class MoneyTests: XCTestCase {

    func testSignConvention() {
        let income = Money(minorUnits: 500_00, currencyCode: "USD")  // $500
        XCTAssertTrue(income.isPositive)
        XCTAssertFalse(income.isNegative)
        XCTAssertFalse(income.isZero)

        let expense = Money(minorUnits: -200_00, currencyCode: "USD")  // -$200
        XCTAssertTrue(expense.isNegative)
        XCTAssertFalse(expense.isPositive)

        let zero = Money.zero()
        XCTAssertTrue(zero.isZero)
    }

    func testArithmetic() {
        let a = Money(minorUnits: 1000_00, currencyCode: "USD")
        let b = Money(minorUnits: 300_00, currencyCode: "USD")
        let sum = a + b
        XCTAssertEqual(sum.minorUnits, 1300_00)

        let diff = a - b
        XCTAssertEqual(diff.minorUnits, 700_00)

        let neg = -b
        XCTAssertEqual(neg.minorUnits, -300_00)
    }

    func testDecimalAmount() {
        let money = Money(minorUnits: 12345, currencyCode: "USD")
        XCTAssertEqual(money.decimalAmount, Decimal(string: "123.45"))
    }

    func testJPYScale() {
        // JPY has no minor units (scale = 1)
        let yen = Money(minorUnits: 1000, currencyCode: "JPY")
        XCTAssertEqual(yen.decimalAmount, 1000)
    }
}

// MARK: - Transaction Entity Tests

@MainActor
final class TransactionEntityTests: XCTestCase {

    private var persistence: PersistenceController!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
    }

    func testIsIncomePositiveAmount() {
        let tx = TransactionEntity(context: persistence.viewContext)
        tx.amountMinorUnits = 500_00  // +$500
        XCTAssertTrue(tx.isIncome, "Positive amount should be income")
        XCTAssertFalse(tx.isExpense, "Positive amount should NOT be expense")
    }

    func testIsExpenseNegativeAmount() {
        let tx = TransactionEntity(context: persistence.viewContext)
        tx.amountMinorUnits = -200_00  // -$200
        XCTAssertTrue(tx.isExpense, "Negative amount should be expense")
        XCTAssertFalse(tx.isIncome, "Negative amount should NOT be income")
    }

    func testZeroAmountIsNeitherIncomeNorExpense() {
        let tx = TransactionEntity(context: persistence.viewContext)
        tx.amountMinorUnits = 0
        XCTAssertFalse(tx.isIncome)
        XCTAssertFalse(tx.isExpense)
    }

    func testCategoryParsing() {
        let tx = TransactionEntity(context: persistence.viewContext)

        tx.categoryId = "income"
        XCTAssertEqual(tx.category, .income)

        tx.categoryId = "groceries"
        XCTAssertEqual(tx.category, .groceries)

        tx.categoryId = nil
        XCTAssertNil(tx.category)

        tx.categoryId = "nonexistent"
        XCTAssertNil(tx.category, "Unknown category should return nil")
    }
}

// MARK: - Date Extension Tests

final class DateExtensionTests: XCTestCase {

    func testStartAndEndOfMonth() {
        // February 15, 2026
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 2
        comps.day = 15
        comps.hour = 12
        let date = Calendar.current.date(from: comps)!

        let start = date.startOfMonth
        let end = date.endOfMonth

        let startComps = Calendar.current.dateComponents([.year, .month, .day], from: start)
        XCTAssertEqual(startComps.year, 2026)
        XCTAssertEqual(startComps.month, 2)
        XCTAssertEqual(startComps.day, 1)

        let endComps = Calendar.current.dateComponents([.year, .month, .day], from: end)
        XCTAssertEqual(endComps.year, 2026)
        XCTAssertEqual(endComps.month, 2)
        XCTAssertEqual(endComps.day, 28)  // 2026 is not a leap year
    }

    func testAddingMonths() {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 1
        comps.day = 15
        let jan = Calendar.current.date(from: comps)!

        let feb = jan.addingMonths(1)
        let febComps = Calendar.current.dateComponents([.month], from: feb)
        XCTAssertEqual(febComps.month, 2)

        let dec = jan.addingMonths(-1)
        let decComps = Calendar.current.dateComponents([.month], from: dec)
        XCTAssertEqual(decComps.month, 12)
    }
}

// MARK: - Transaction Service Tests

@MainActor
final class TransactionServiceTests: XCTestCase {

    private var persistence: PersistenceController!
    private var service: TransactionService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        service = TransactionService(persistence: persistence)
    }

    func testCreateIncomeTransaction() {
        let tx = service.createTransaction(
            amount: 500_00,  // +$500 = income
            categoryId: "income",
            note: "Salary",
            date: Date()
        )

        XCTAssertTrue(tx.isIncome, "Created transaction should be income")
        XCTAssertEqual(tx.amountMinorUnits, 500_00)
        XCTAssertEqual(tx.categoryId, "income")
    }

    func testCreateExpenseTransaction() {
        let tx = service.createTransaction(
            amount: -50_00,  // -$50 = expense
            categoryId: "groceries",
            note: "Supermarket",
            date: Date()
        )

        XCTAssertTrue(tx.isExpense)
        XCTAssertEqual(tx.amountMinorUnits, -50_00)
    }

    func testTotalIncomeForMonth() {
        let now = Date()

        // 3 income transactions
        service.createTransaction(amount: 300_000, categoryId: "income", date: now)  // $3,000
        service.createTransaction(amount: 200_000, categoryId: "income", date: now)  // $2,000
        service.createTransaction(amount: 100_000, categoryId: "income", date: now)  // $1,000

        // 1 expense (should NOT count)
        service.createTransaction(amount: -50_000, categoryId: "groceries", date: now)

        let income = service.totalIncome(for: now)
        XCTAssertEqual(income, 600_000, "Total income should be $6,000 (600000 minor units)")
    }

    func testTotalSpendingForMonth() {
        let now = Date()

        // 2 expense transactions
        service.createTransaction(amount: -50_00, categoryId: "groceries", date: now)
        service.createTransaction(amount: -120_00, categoryId: "housing", date: now)

        // 1 income (should NOT count)
        service.createTransaction(amount: 300_000, categoryId: "income", date: now)

        let spending = service.totalSpending(for: now)
        XCTAssertEqual(spending, 170_00, "Total spending should be $170 (17000 minor units)")
    }

    func testFetchTransactionsFiltersByMonth() {
        let now = Date()
        let lastMonth = now.addingMonths(-1)

        // This month
        service.createTransaction(amount: 100_00, categoryId: "income", date: now)
        service.createTransaction(amount: -50_00, categoryId: "groceries", date: now)

        // Last month
        service.createTransaction(amount: 200_00, categoryId: "income", date: lastMonth)

        let thisMonthTxs = service.fetchTransactions(for: now)
        XCTAssertEqual(thisMonthTxs.count, 2, "Should only get this month's transactions")

        let lastMonthTxs = service.fetchTransactions(for: lastMonth)
        XCTAssertEqual(lastMonthTxs.count, 1, "Should only get last month's transactions")
    }

    func testFetchAllTransactionsNoFilter() {
        let now = Date()
        let lastMonth = now.addingMonths(-1)

        service.createTransaction(amount: 100_00, date: now)
        service.createTransaction(amount: 200_00, date: lastMonth)

        let all = service.fetchTransactions()
        XCTAssertEqual(all.count, 2, "No filter should return all transactions")
    }

    func testDeleteTransactionReversesAccountBalance() {
        let account = AccountEntity(context: persistence.viewContext)
        account.id = UUID()
        account.name = "Checking"
        account.type = "checking"
        account.balanceMinorUnits = 1000_00  // $1,000
        try! persistence.viewContext.save()

        let tx = service.createTransaction(
            amount: 500_00,
            categoryId: "income",
            date: Date(),
            account: account
        )

        XCTAssertEqual(account.balanceMinorUnits, 1500_00, "Balance should increase after income")

        service.deleteTransaction(tx)
        XCTAssertEqual(account.balanceMinorUnits, 1000_00, "Balance should revert after delete")
    }
}

// MARK: - Account + Net Worth Tests

@MainActor
final class AccountNetWorthTests: XCTestCase {

    private var persistence: PersistenceController!
    private var accountService: AccountService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        accountService = AccountService(persistence: persistence)
    }

    func testAssetContributesPositiveNetWorth() {
        let account = accountService.createAccount(
            name: "Savings",
            type: .savings,
            balance: 500_000  // $5,000
        )
        XCTAssertEqual(account.netWorthContribution, 500_000)
        XCTAssertFalse(account.isLiability)
    }

    func testLiabilityContributesNegativeNetWorth() {
        let account = accountService.createAccount(
            name: "Credit Card",
            type: .credit,
            balance: -300_00  // -$300 owed
        )
        XCTAssertTrue(account.isLiability)
        // netWorthContribution for liability = -abs(balance)
        XCTAssertEqual(account.netWorthContribution, -300_00)
    }

    func testPassiveIncomeFromSavingsRate() {
        let account = accountService.createAccount(
            name: "Savings",
            type: .savings,
            balance: 1_200_000,  // $12,000
            annualInterestRate: Decimal(string: "0.12")!  // 12% annual
        )
        // Monthly passive = 1_200_000 * 0.12 / 12 = 12,000 minor units = $120/mo
        let monthly = account.monthlyPassiveIncome
        XCTAssertEqual(monthly.minorUnits, 12_000, "Should be $120/mo passive income")
    }

    func testLiabilityHasNoPassiveIncome() {
        let account = accountService.createAccount(
            name: "Loan",
            type: .loan,
            balance: -100_000,
            annualInterestRate: Decimal(string: "0.05")!
        )
        XCTAssertTrue(account.monthlyPassiveIncome.isZero,
                       "Liabilities should not generate passive income")
    }

    func testTransactionUpdatesAccountBalance() {
        let account = accountService.createAccount(
            name: "Checking",
            type: .checking,
            balance: 1000_00  // $1,000
        )

        let txService = TransactionService(persistence: persistence)

        // Income: +$500
        txService.createTransaction(amount: 500_00, categoryId: "income", date: Date(), account: account)
        XCTAssertEqual(account.balanceMinorUnits, 1500_00, "Balance should be $1,500 after income")

        // Expense: -$200
        txService.createTransaction(amount: -200_00, categoryId: "groceries", date: Date(), account: account)
        XCTAssertEqual(account.balanceMinorUnits, 1300_00, "Balance should be $1,300 after expense")
    }
}

// MARK: - CashFlow Service Tests

@MainActor
final class CashFlowServiceTests: XCTestCase {

    private var persistence: PersistenceController!
    private var accountService: AccountService!
    private var transactionService: TransactionService!
    private var cashFlowService: CashFlowService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        accountService = AccountService(persistence: persistence)
        transactionService = TransactionService(persistence: persistence)
        cashFlowService = CashFlowService(
            persistence: persistence,
            accountService: accountService,
            transactionService: transactionService
        )
    }

    func testNetWorthWithAssetsAndLiabilities() {
        accountService.createAccount(name: "Savings", type: .savings, balance: 500_000)   // +$5,000
        accountService.createAccount(name: "Investment", type: .investment, balance: 1_000_000)  // +$10,000
        accountService.createAccount(name: "Credit Card", type: .credit, balance: -200_000)  // -$2,000

        let nw = cashFlowService.netWorth()
        // Savings 500k + Investment 1M + Credit(-200k → -200k) = 1,300,000
        XCTAssertEqual(nw, 1_300_000, "Net worth should be $13,000 (1,300,000 minor units)")
    }

    func testNetWorthWithNoAccounts() {
        let nw = cashFlowService.netWorth()
        XCTAssertEqual(nw, 0, "Net worth with no accounts should be 0")
    }

    func testActiveIncomeFromTransactions() {
        let now = Date()
        // 2 salary deposits this month
        transactionService.createTransaction(amount: 300_000, categoryId: "income", date: now)
        transactionService.createTransaction(amount: 200_000, categoryId: "income", date: now)

        let active = cashFlowService.activeIncome(for: now)
        XCTAssertEqual(active, 500_000, "Active income should be $5,000")
    }

    func testTotalMonthlyPassiveIncome() {
        // Savings: $12,000 at 12% = $120/mo
        accountService.createAccount(
            name: "Savings",
            type: .savings,
            balance: 1_200_000,
            annualInterestRate: Decimal(string: "0.12")!
        )
        // Investment: $100,000 at 10% = ~$833/mo
        accountService.createAccount(
            name: "Stocks",
            type: .investment,
            balance: 10_000_000,
            expectedAnnualReturn: Decimal(string: "0.10")!
        )

        let passive = cashFlowService.totalMonthlyPassiveIncome()
        // 12,000 + 83,333 = 95,333
        XCTAssertEqual(passive, 12_000 + 83_333, "Passive income should sum both accounts")
    }

    func testTotalExpensesFromTransactions() {
        let now = Date()
        transactionService.createTransaction(amount: -50_00, categoryId: "groceries", date: now)
        transactionService.createTransaction(amount: -120_00, categoryId: "housing", date: now)
        // Income should not count
        transactionService.createTransaction(amount: 300_000, categoryId: "income", date: now)

        let expenses = cashFlowService.totalExpenses(for: now)
        XCTAssertEqual(expenses, 170_00, "Total expenses should be $170")
    }

    func testExpensesByGroup() {
        let now = Date()
        // Needs: housing + groceries
        transactionService.createTransaction(amount: -120_000, categoryId: "housing", date: now)
        transactionService.createTransaction(amount: -30_000, categoryId: "groceries", date: now)
        // Wants: dining + entertainment
        transactionService.createTransaction(amount: -15_000, categoryId: "dining", date: now)
        transactionService.createTransaction(amount: -10_000, categoryId: "entertainment", date: now)

        let groups = cashFlowService.expensesByGroup(for: now)

        let needs = groups.first { $0.group == .needs }
        XCTAssertNotNil(needs, "Should have 'Needs' group")
        XCTAssertEqual(needs?.total, 150_000, "Needs should total $1,500")

        let wants = groups.first { $0.group == .wants }
        XCTAssertNotNil(wants, "Should have 'Wants' group")
        XCTAssertEqual(wants?.total, 25_000, "Wants should total $250")
    }

    func testFreedomRatio() {
        let now = Date()

        // Passive income: $12,000 at 12% = $120/mo passive
        accountService.createAccount(
            name: "Savings",
            type: .savings,
            balance: 1_200_000,
            annualInterestRate: Decimal(string: "0.12")!
        )

        // Expenses: $120/mo
        transactionService.createTransaction(amount: -120_00, categoryId: "groceries", date: now)

        let ratio = cashFlowService.freedomRatio(for: now)
        // passive (12_000) / expenses (12_000) = 1.0
        XCTAssertEqual(ratio, 1, "Freedom ratio should be 1.0 (passive covers expenses)")
    }

    func testFreedomRatioZeroExpenses() {
        // Passive income exists but no expenses
        accountService.createAccount(
            name: "Savings",
            type: .savings,
            balance: 1_200_000,
            annualInterestRate: Decimal(string: "0.12")!
        )

        let ratio = cashFlowService.freedomRatio(for: Date())
        XCTAssertEqual(ratio, 1, "With passive income but zero expenses, should be 1")
    }

    func testFreedomRatioNoPassiveNoExpenses() {
        let ratio = cashFlowService.freedomRatio(for: Date())
        XCTAssertEqual(ratio, 0, "With nothing, freedom ratio should be 0")
    }
}

// MARK: - Integration: Full Pipeline Test

@MainActor
final class FullPipelineTests: XCTestCase {

    private var persistence: PersistenceController!
    private var accountService: AccountService!
    private var transactionService: TransactionService!
    private var cashFlowService: CashFlowService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        accountService = AccountService(persistence: persistence)
        transactionService = TransactionService(persistence: persistence)
        cashFlowService = CashFlowService(
            persistence: persistence,
            accountService: accountService,
            transactionService: transactionService
        )
    }

    /// Simulates what the user described: 8 salary income transactions.
    /// Verifies the full data pipeline from transaction to dashboard numbers.
    func testSalaryTransactionsShowOnDashboard() {
        let now = Date()

        // Create a checking account
        let checking = accountService.createAccount(
            name: "Checking",
            type: .checking,
            balance: 0
        )

        // Add 8 salary transactions (income, category "income", $3,000 each)
        for _ in 0..<8 {
            transactionService.createTransaction(
                amount: 300_000,     // +$3,000
                categoryId: "income",
                note: "Salary",
                date: now,
                account: checking
            )
        }

        // Verify transactions exist
        let allTx = transactionService.fetchTransactions(for: now)
        XCTAssertEqual(allTx.count, 8, "Should have 8 transactions")

        // Verify all are income
        let incomeTx = allTx.filter { $0.isIncome }
        XCTAssertEqual(incomeTx.count, 8, "All 8 should be income (positive amount)")

        // Verify TransactionService.totalIncome
        let totalIncome = transactionService.totalIncome(for: now)
        XCTAssertEqual(totalIncome, 8 * 300_000, "Total income = 8 * $3,000 = $24,000")

        // Verify CashFlowService.activeIncome
        let activeIncome = cashFlowService.activeIncome(for: now)
        XCTAssertEqual(activeIncome, 8 * 300_000, "Active income should match")

        // Verify no expenses
        let totalExpenses = cashFlowService.totalExpenses(for: now)
        XCTAssertEqual(totalExpenses, 0, "No expense transactions → 0 expenses")

        // Verify account balance was updated
        XCTAssertEqual(checking.balanceMinorUnits, 8 * 300_000,
                        "Account balance should reflect all 8 deposits")

        // Verify net worth
        let nw = cashFlowService.netWorth()
        XCTAssertEqual(nw, 8 * 300_000,
                        "Net worth = checking account balance = $24,000")
    }

    /// Test: income transactions WITHOUT linking to an account
    /// This is a common scenario — user adds transactions but has no accounts.
    func testIncomeWithoutAccountDoesNotAffectNetWorth() {
        let now = Date()

        // Add income but NOT linked to any account
        for _ in 0..<8 {
            transactionService.createTransaction(
                amount: 300_000,
                categoryId: "income",
                note: "Salary",
                date: now,
                account: nil  // ← no account!
            )
        }

        // Income IS tracked in transactions
        let totalIncome = transactionService.totalIncome(for: now)
        XCTAssertEqual(totalIncome, 8 * 300_000, "Income should still total $24,000")

        // Active income IS calculated
        let activeIncome = cashFlowService.activeIncome(for: now)
        XCTAssertEqual(activeIncome, 8 * 300_000, "Active income should still be $24,000")

        // But net worth IS ZERO because no accounts exist
        let nw = cashFlowService.netWorth()
        XCTAssertEqual(nw, 0,
                        "Net worth should be 0 when transactions aren't linked to accounts!")
    }

    /// Test: DashboardViewModel loads real data
    func testDashboardViewModelLoadsData() {
        let now = Date()

        // Create account with balance
        let savings = accountService.createAccount(
            name: "Savings",
            type: .savings,
            balance: 1_000_000,  // $10,000
            annualInterestRate: Decimal(string: "0.06")!  // 6% APY
        )

        // Add income transaction linked to account
        transactionService.createTransaction(
            amount: 500_000,  // $5,000 salary
            categoryId: "income",
            date: now,
            account: savings
        )

        // Add expense
        transactionService.createTransaction(
            amount: -200_000,  // $2,000 rent
            categoryId: "housing",
            date: now,
            account: savings
        )

        // Create DashboardViewModel with our test services
        let viewModel = DashboardViewModel(
            cashFlowService: cashFlowService,
            transactionService: transactionService,
            goalService: GoalService(persistence: persistence)
        )

        // Monthly income = active ($5,000) + passive ($10,000 * 6% / 12 ≈ $50)
        // Note: account balance was updated by transactions, so it's $10,000 + $5,000 - $2,000 = $13,000
        // Passive = $13,000 * 0.06 / 12 = $65
        let expectedPassive: Int64 = 1_300_000 * 6 / 1200  // = 6500 minor units = $65
        let expectedActive: Int64 = 500_000
        let expectedExpenses: Int64 = 200_000

        XCTAssertEqual(viewModel.monthlyIncome.minorUnits, expectedActive + expectedPassive,
                        "Dashboard income should be active + passive")
        XCTAssertEqual(viewModel.monthlyExpenses.minorUnits, expectedExpenses,
                        "Dashboard expenses should be $2,000")
        XCTAssertEqual(viewModel.monthlySurplus.minorUnits,
                        (expectedActive + expectedPassive) - expectedExpenses,
                        "Surplus = income - expenses")
        XCTAssertEqual(viewModel.netWorth.minorUnits, 1_300_000,
                        "Net worth = updated savings balance")

        // Recent transactions
        XCTAssertEqual(viewModel.recentTransactions.count, 2,
                        "Should have 2 recent transactions")
    }

    /// Verify that the month filter actually works for the dashboard
    func testDashboardOnlyShowsCurrentMonthData() {
        let now = Date()
        let lastMonth = now.addingMonths(-1)

        // Income last month
        transactionService.createTransaction(
            amount: 300_000,
            categoryId: "income",
            date: lastMonth
        )

        // Income this month
        transactionService.createTransaction(
            amount: 500_000,
            categoryId: "income",
            date: now
        )

        // DashboardViewModel uses Date() (current month) for calculations
        let viewModel = DashboardViewModel(
            cashFlowService: cashFlowService,
            transactionService: transactionService,
            goalService: GoalService(persistence: persistence)
        )

        // activeIncome should only count THIS month's transactions
        let active = cashFlowService.activeIncome(for: now)
        XCTAssertEqual(active, 500_000,
                        "Should only count current month income ($5,000)")

        // monthlyIncome = active + passive (no accounts, so 0 passive)
        XCTAssertEqual(viewModel.monthlyIncome.minorUnits, 500_000,
                        "Dashboard should show this month's income only")
    }

    /// Verify that expense categories correctly group
    func testExpenseCategoryGrouping() {
        let now = Date()

        // Needs
        transactionService.createTransaction(amount: -100_000, categoryId: "housing", date: now)
        transactionService.createTransaction(amount: -30_000, categoryId: "groceries", date: now)
        transactionService.createTransaction(amount: -10_000, categoryId: "utilities", date: now)

        // Wants
        transactionService.createTransaction(amount: -20_000, categoryId: "dining", date: now)
        transactionService.createTransaction(amount: -15_000, categoryId: "entertainment", date: now)

        // Debt service
        transactionService.createTransaction(amount: -50_000, categoryId: "debt", date: now)

        let groups = cashFlowService.expensesByGroup(for: now)

        let needs = groups.first { $0.group == .needs }
        XCTAssertEqual(needs?.total, 140_000, "Needs = housing + groceries + utilities = $1,400")

        let wants = groups.first { $0.group == .wants }
        XCTAssertEqual(wants?.total, 35_000, "Wants = dining + entertainment = $350")

        let debt = groups.first { $0.group == .debtService }
        XCTAssertEqual(debt?.total, 50_000, "Debt Service = $500")
    }
}

// MARK: - TransactionsViewModel Tests

@MainActor
final class TransactionsViewModelTests: XCTestCase {

    private var persistence: PersistenceController!
    private var transactionService: TransactionService!
    private var cashFlowService: CashFlowService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        let accountService = AccountService(persistence: persistence)
        transactionService = TransactionService(persistence: persistence)
        cashFlowService = CashFlowService(
            persistence: persistence,
            accountService: accountService,
            transactionService: transactionService
        )
    }

    func testViewModelLoadsCashFlowSummary() {
        let now = Date()

        // Income
        transactionService.createTransaction(amount: 500_000, categoryId: "income", date: now)
        // Expenses
        transactionService.createTransaction(amount: -100_000, categoryId: "housing", date: now)
        transactionService.createTransaction(amount: -30_000, categoryId: "groceries", date: now)

        let viewModel = TransactionsViewModel(
            transactionService: transactionService,
            cashFlowService: cashFlowService
        )

        XCTAssertEqual(viewModel.transactions.count, 3)
        XCTAssertEqual(viewModel.totalIncome.minorUnits, 500_000, "Income = $5,000")
        XCTAssertEqual(viewModel.totalSpending.minorUnits, 130_000, "Spending = $1,300")
        XCTAssertEqual(viewModel.activeIncome.minorUnits, 500_000, "Active income = $5,000")
        XCTAssertFalse(viewModel.netCashFlow.isNegative, "Net cash flow should be positive")
    }

    func testMonthNavigation() {
        let now = Date()
        let lastMonth = now.addingMonths(-1)

        transactionService.createTransaction(amount: 100_000, categoryId: "income", date: now)
        transactionService.createTransaction(amount: 200_000, categoryId: "income", date: lastMonth)

        let viewModel = TransactionsViewModel(
            transactionService: transactionService,
            cashFlowService: cashFlowService
        )

        // Current month
        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertEqual(viewModel.totalIncome.minorUnits, 100_000)

        // Go back one month
        viewModel.changeMonth(by: -1)
        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertEqual(viewModel.totalIncome.minorUnits, 200_000)
    }
}

// MARK: - Staleness / Refresh Tests (the actual bug)

@MainActor
final class StalenessTests: XCTestCase {

    private var persistence: PersistenceController!
    private var accountService: AccountService!
    private var transactionService: TransactionService!
    private var cashFlowService: CashFlowService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        accountService = AccountService(persistence: persistence)
        transactionService = TransactionService(persistence: persistence)
        cashFlowService = CashFlowService(
            persistence: persistence,
            accountService: accountService,
            transactionService: transactionService
        )
    }

    /// THE BUG: BalanceSheetViewModel shows 0 after transactions added elsewhere.
    /// BalanceSheetViewModel.loadData() is only called in init().
    /// If transactions change account balance AFTER init, the view model is stale.
    func testBalanceSheetViewModelShowsStaleData() {
        // 1. Create an account with $0 balance
        let checking = accountService.createAccount(
            name: "Checking",
            type: .checking,
            balance: 0
        )

        // 2. Create BalanceSheetViewModel (simulates first tab switch to Wealth)
        let viewModel = BalanceSheetViewModel(cashFlowService: cashFlowService)

        // 3. At this point, net worth = 0, account balance = 0
        XCTAssertEqual(viewModel.netWorth.minorUnits, 0, "Initially $0")

        // 4. Add 8 salary transactions (simulates user going to Transactions tab)
        for _ in 0..<8 {
            transactionService.createTransaction(
                amount: 100_000,  // +$1,000 each
                categoryId: "income",
                date: Date(),
                account: checking
            )
        }

        // 5. Account balance DID update in Core Data
        XCTAssertEqual(checking.balanceMinorUnits, 800_000,
                        "Core Data account has $8,000 balance")

        // 6. BUT the view model is STALE — still shows $0
        XCTAssertEqual(viewModel.netWorth.minorUnits, 0,
                        "BUG: ViewModel is stale — shows $0 instead of $8,000")

        // 7. After calling loadData() (which .onAppear now triggers), it refreshes
        viewModel.loadData()
        XCTAssertEqual(viewModel.netWorth.minorUnits, 800_000,
                        "After refresh, net worth should be $8,000")
    }

    /// Same bug for DashboardViewModel
    func testDashboardViewModelShowsStaleData() {
        let checking = accountService.createAccount(
            name: "Checking",
            type: .checking,
            balance: 0
        )

        // Create DashboardViewModel (simulates app launch)
        let viewModel = DashboardViewModel(
            cashFlowService: cashFlowService,
            transactionService: transactionService,
            goalService: GoalService(persistence: persistence)
        )

        // Initially all zeros
        XCTAssertEqual(viewModel.monthlyIncome.minorUnits, 0)
        XCTAssertEqual(viewModel.netWorth.minorUnits, 0)

        // Add transactions (simulates user adding from Transactions tab)
        transactionService.createTransaction(
            amount: 500_000,
            categoryId: "income",
            date: Date(),
            account: checking
        )

        // ViewModel is stale
        XCTAssertEqual(viewModel.monthlyIncome.minorUnits, 0,
                        "BUG: Dashboard still shows $0 income")

        // After refresh (which .onAppear now triggers)
        viewModel.loadAll()
        XCTAssertEqual(viewModel.monthlyIncome.minorUnits, 500_000,
                        "After refresh, income should be $5,000")
        XCTAssertEqual(viewModel.netWorth.minorUnits, 500_000,
                        "After refresh, net worth should be $5,000")
        XCTAssertEqual(viewModel.recentTransactions.count, 1,
                        "After refresh, should have 1 recent transaction")
    }

    /// Verify the account balance vs BalanceSheet "assetRow" discrepancy.
    /// The account managed object updates live, but the ViewModel's @Published
    /// properties (totalAssets, netWorth) are stale until loadData() is called.
    func testAccountBalanceLiveVsViewModelStale() {
        let checking = accountService.createAccount(
            name: "Checking",
            type: .checking,
            balance: 0
        )

        let viewModel = BalanceSheetViewModel(cashFlowService: cashFlowService)

        // Add transaction
        transactionService.createTransaction(
            amount: 800_000,
            categoryId: "income",
            date: Date(),
            account: checking
        )

        // The Core Data entity is LIVE — shows updated balance
        XCTAssertEqual(checking.balanceMinorUnits, 800_000,
                        "Account entity is live: $8,000")
        XCTAssertEqual(checking.balance.formatted,
                        Money(minorUnits: 800_000, currencyCode: "USD").formatted,
                        "Account.balance.formatted should show $8,000")

        // But ViewModel's computed totals are STALE
        XCTAssertEqual(viewModel.netWorth.minorUnits, 0,
                        "ViewModel netWorth is stale: $0")
        XCTAssertEqual(viewModel.totalAssets.minorUnits, 0,
                        "ViewModel totalAssets is stale: $0")

        // The account rows in the LIST read from the fetched managed objects.
        // The assetGroups were fetched during init, so they contain the
        // original account with balance=0 at fetch time. BUT the managed
        // object is live, so account.balance.formatted might show the
        // updated value depending on when SwiftUI re-renders.
        //
        // The NET WORTH HEADER however reads from viewModel.netWorth which
        // is a @Published Money value — definitely stale.

        // Fix: loadData() refreshes everything
        viewModel.loadData()
        XCTAssertEqual(viewModel.netWorth.minorUnits, 800_000, "Fixed: $8,000")
        XCTAssertEqual(viewModel.totalAssets.minorUnits, 800_000, "Fixed: $8,000")

        // Verify asset groups are also refreshed
        let cashGroup = viewModel.assetGroups.first { $0.groupName == "Cash & Savings" }
        XCTAssertNotNil(cashGroup)
        XCTAssertEqual(cashGroup?.subtotal, 800_000, "Cash & Savings subtotal = $8,000")
    }
}

// MARK: - Recurring Rule Tests

@MainActor
final class RecurringRuleTests: XCTestCase {

    private var persistence: PersistenceController!
    private var recurringService: RecurringRuleService!
    private var transactionService: TransactionService!
    private var accountService: AccountService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        recurringService = RecurringRuleService(persistence: persistence)
        transactionService = TransactionService(persistence: persistence)
        accountService = AccountService(persistence: persistence)
    }

    /// Basic: a rule with nextDueDate in the past generates a transaction
    func testGenerateSingleDueTransaction() {
        let yesterday = Date().addingTimeInterval(-86400)

        recurringService.createRule(
            amount: 800_000,  // +$8,000 income
            categoryId: "income",
            note: "Salary",
            frequency: .monthly,
            nextDueDate: yesterday
        )

        recurringService.generateDueTransactions()

        let txs = transactionService.fetchTransactions()
        XCTAssertEqual(txs.count, 1, "Should generate 1 transaction")
        XCTAssertEqual(txs.first?.amountMinorUnits, 800_000)
        XCTAssertTrue(txs.first?.isRecurring == true)
        XCTAssertEqual(txs.first?.note, "Salary")
    }

    /// THE BUG FIX: catch-up generates ALL overdue periods, not just one.
    /// If nextDueDate was Jan 2 and today is Feb 8, should generate Jan + Feb.
    func testCatchUpGeneratesAllOverduePeriods() {
        // Rule started 3 months ago
        let threeMonthsAgo = Date().addingMonths(-3)

        recurringService.createRule(
            amount: 800_000,  // +$8,000/mo
            categoryId: "income",
            note: "Salary",
            frequency: .monthly,
            nextDueDate: threeMonthsAgo
        )

        recurringService.generateDueTransactions()

        let txs = transactionService.fetchTransactions()
        // 3 months ago, 2 months ago, 1 month ago = 3 transactions
        // (this month's due date hasn't arrived if threeMonthsAgo is > 3 months)
        // Actually: depends on exact dates. Let's just check >= 3
        XCTAssertGreaterThanOrEqual(txs.count, 3,
            "Should catch up all overdue months (at least 3). Got: \(txs.count)")

        // All should be $8,000 income
        for tx in txs {
            XCTAssertEqual(tx.amountMinorUnits, 800_000)
            XCTAssertTrue(tx.isRecurring)
        }
    }

    /// Rule with account updates account balance for each generated transaction
    func testRecurringWithAccountUpdatesBalance() {
        let checking = accountService.createAccount(
            name: "Checking",
            type: .checking,
            balance: 0
        )

        let twoMonthsAgo = Date().addingMonths(-2)

        recurringService.createRule(
            amount: 800_000,  // +$8,000/mo
            categoryId: "income",
            note: "Salary",
            frequency: .monthly,
            nextDueDate: twoMonthsAgo,
            account: checking
        )

        recurringService.generateDueTransactions()

        let txs = transactionService.fetchTransactions()
        XCTAssertGreaterThanOrEqual(txs.count, 2, "At least 2 months of catch-up")

        // Account balance should reflect all generated transactions
        let expectedBalance = Int64(txs.count) * 800_000
        XCTAssertEqual(checking.balanceMinorUnits, expectedBalance,
            "Account balance should be \(txs.count) * $8,000 = $\(expectedBalance / 100)")
    }

    /// Rule without account: transactions are created but no balance update
    func testRecurringWithoutAccountNoBalanceUpdate() {
        let yesterday = Date().addingTimeInterval(-86400)

        recurringService.createRule(
            amount: 800_000,
            categoryId: "income",
            note: "Salary",
            frequency: .monthly,
            nextDueDate: yesterday,
            account: nil  // ← no account!
        )

        recurringService.generateDueTransactions()

        let txs = transactionService.fetchTransactions()
        XCTAssertEqual(txs.count, 1, "Transaction should be created")
        XCTAssertNil(txs.first?.account, "Transaction should have no account")
    }

    /// Rule with future nextDueDate should NOT generate any transaction
    func testFutureRuleDoesNotGenerate() {
        let tomorrow = Date().addingTimeInterval(86400)

        recurringService.createRule(
            amount: 800_000,
            categoryId: "income",
            frequency: .monthly,
            nextDueDate: tomorrow
        )

        recurringService.generateDueTransactions()

        let txs = transactionService.fetchTransactions()
        XCTAssertEqual(txs.count, 0, "Future rule should not generate transactions")
    }

    /// After generating, nextDueDate should be in the future
    func testNextDueDateAdvancesToFuture() {
        let twoMonthsAgo = Date().addingMonths(-2)

        let rule = recurringService.createRule(
            amount: 800_000,
            categoryId: "income",
            frequency: .monthly,
            nextDueDate: twoMonthsAgo
        )

        recurringService.generateDueTransactions()

        // After catch-up, nextDueDate should be in the future
        XCTAssertNotNil(rule.nextDueDate)
        XCTAssertTrue(rule.nextDueDate! > Date(),
            "nextDueDate should be in the future after catch-up. Got: \(rule.nextDueDate!)")
    }

    /// Weekly frequency catch-up
    func testWeeklyCatchUp() {
        let threeWeeksAgo = Date().addingTimeInterval(-21 * 86400)

        recurringService.createRule(
            amount: -50_000,  // -$500 expense
            categoryId: "groceries",
            note: "Weekly groceries",
            frequency: .weekly,
            nextDueDate: threeWeeksAgo
        )

        recurringService.generateDueTransactions()

        let txs = transactionService.fetchTransactions()
        XCTAssertGreaterThanOrEqual(txs.count, 3,
            "Should have at least 3 weekly transactions. Got: \(txs.count)")

        for tx in txs {
            XCTAssertTrue(tx.isExpense, "Should be expense")
            XCTAssertEqual(tx.amountMinorUnits, -50_000)
        }
    }

    /// Full scenario: user creates salary rule from Jan 2, opens app on Feb 8
    func testUserScenarioSalaryFromJanuary() {
        // Create account
        let checking = accountService.createAccount(
            name: "Checking",
            type: .checking,
            balance: 0
        )

        // Jan 2, 2026
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 1
        comps.day = 2
        let jan2 = Calendar.current.date(from: comps)!

        // Create monthly salary rule: $8,000 from Jan 2
        let rule = recurringService.createRule(
            amount: 800_000,
            categoryId: "income",
            note: "Salary",
            frequency: .monthly,
            nextDueDate: jan2,
            account: checking
        )

        // Generate (today is Feb 8, 2026)
        recurringService.generateDueTransactions()

        let txs = transactionService.fetchTransactions()

        // Jan 2 is overdue → generates tx, advances to Feb 2
        // Feb 2 is overdue → generates tx, advances to Mar 2
        // Mar 2 is in future → stops
        XCTAssertEqual(txs.count, 2,
            "Should have 2 transactions (Jan + Feb). Got: \(txs.count)")

        // Account balance = 2 * $8,000 = $16,000
        XCTAssertEqual(checking.balanceMinorUnits, 2 * 800_000,
            "Account should have $16,000")

        // nextDueDate should be Mar 2
        let nextComps = Calendar.current.dateComponents([.year, .month, .day], from: rule.nextDueDate!)
        XCTAssertEqual(nextComps.month, 3, "Next due should be March")
        XCTAssertEqual(nextComps.day, 2, "Next due should be 2nd")

        // Income should show in CashFlowService
        let cashFlowService = CashFlowService(
            persistence: persistence,
            accountService: accountService,
            transactionService: transactionService
        )

        // Net worth = account balance
        let nw = cashFlowService.netWorth()
        XCTAssertEqual(nw, 1_600_000, "Net worth should be $16,000")

        // Check income for January
        let janIncome = cashFlowService.activeIncome(for: jan2)
        XCTAssertEqual(janIncome, 800_000, "Jan income should be $8,000")

        // Check income for February
        let feb2 = jan2.addingMonths(1)
        let febIncome = cashFlowService.activeIncome(for: feb2)
        XCTAssertEqual(febIncome, 800_000, "Feb income should be $8,000")
    }
}
