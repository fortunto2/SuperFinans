//
//  PersistenceController.swift
//  SuperFinans
//
//  Core Data stack with NSPersistentCloudKitContainer.
//  Programmatic model (no .xcdatamodeld file).
//

import CoreData
import Foundation

final class PersistenceController: @unchecked Sendable {

    // MARK: - Singleton

    nonisolated(unsafe) static let shared = PersistenceController()

    nonisolated(unsafe) static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext

        // Sample account
        let account = AccountEntity(context: ctx)
        account.id = UUID()
        account.name = "Checking"
        account.type = "checking"
        account.currencyCode = "USD"
        account.balanceMinorUnits = 250000 // $2,500.00
        account.iconName = "building.columns.fill"
        account.colorHex = "42A5F5"
        account.sortOrder = 0
        account.isArchived = false
        account.createdAt = Date()
        account.updatedAt = Date()

        // Sample goal
        let goal = GoalEntity(context: ctx)
        goal.id = UUID()
        goal.name = "Emergency Fund"
        goal.targetAmountMinorUnits = 1000000 // $10,000
        goal.currentAmountMinorUnits = 350000  // $3,500
        goal.currencyCode = "USD"
        goal.targetDate = Date().addingTimeInterval(365 * 24 * 3600)
        goal.annualInterestRate = NSDecimalNumber(decimal: Decimal(0.045))
        goal.compoundingFrequency = "monthly"
        goal.monthlyContributionMinorUnits = 50000 // $500
        goal.iconName = "shield.fill"
        goal.colorHex = "4ECDC4"
        goal.sortOrder = 0
        goal.isArchived = false
        goal.sharingLevel = "private"
        goal.createdAt = Date()
        goal.updatedAt = Date()

        // Sample transactions
        let categories = ["groceries", "dining", "transportation", "entertainment", "housing"]
        let amounts: [Int64] = [-5500, -2300, -4500, -1500, -120000]
        for i in 0..<5 {
            let tx = TransactionEntity(context: ctx)
            tx.id = UUID()
            tx.amountMinorUnits = amounts[i]
            tx.currencyCode = "USD"
            tx.categoryId = categories[i]
            tx.note = "Sample transaction \(i + 1)"
            tx.date = Date().addingTimeInterval(TimeInterval(-i * 86400))
            tx.isRecurring = false
            tx.createdAt = Date()
            tx.updatedAt = Date()
            tx.account = account
        }

        do { try ctx.save() } catch {
            fatalError("Preview Core Data save failed: \(error)")
        }
        return controller
    }()

    // MARK: - Core Data Stack

    let container: NSPersistentCloudKitContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Init

    init(inMemory: Bool = false) {
        let model = Self.createManagedObjectModel()
        container = NSPersistentCloudKitContainer(name: "SuperFinans", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure for CloudKit
            let description = container.persistentStoreDescriptions.first
            description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
                #if DEBUG
                fatalError("Failed to load Core Data store: \(error)")
                #endif
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    // MARK: - Save

    func save() {
        let context = viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
            #if DEBUG
            fatalError("Core Data save error: \(error)")
            #endif
        }
    }

    // MARK: - Background

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }

    // MARK: - Programmatic Model

    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // --- AccountEntity ---
        let accountEntity = NSEntityDescription()
        accountEntity.name = "AccountEntity"
        accountEntity.managedObjectClassName = "AccountEntity"

        let accountId = attr("id", .UUIDAttributeType, optional: true)
        let accountName = attr("name", .stringAttributeType, defaultValue: "")
        let accountType = attr("type", .stringAttributeType, defaultValue: "checking")
        let accountCurrency = attr("currencyCode", .stringAttributeType, defaultValue: "USD")
        let accountBalance = attr("balanceMinorUnits", .integer64AttributeType, defaultValue: 0)
        let accountIcon = attr("iconName", .stringAttributeType, defaultValue: "building.columns.fill")
        let accountColor = attr("colorHex", .stringAttributeType, defaultValue: "42A5F5")
        let accountSort = attr("sortOrder", .integer32AttributeType, defaultValue: 0)
        let accountArchived = attr("isArchived", .booleanAttributeType, defaultValue: false)
        let accountCreated = attr("createdAt", .dateAttributeType, optional: true)
        let accountUpdated = attr("updatedAt", .dateAttributeType, optional: true)
        let accountModifiedBy = attr("lastModifiedBy", .stringAttributeType, optional: true)
        let accountRate = attr("annualInterestRate", .decimalAttributeType, optional: true)
        let accountExpectedReturn = attr("expectedAnnualReturn", .decimalAttributeType, optional: true)
        let accountTicker = attr("benchmarkTicker", .stringAttributeType, optional: true)

        // --- TransactionEntity ---
        let transactionEntity = NSEntityDescription()
        transactionEntity.name = "TransactionEntity"
        transactionEntity.managedObjectClassName = "TransactionEntity"

        let txId = attr("id", .UUIDAttributeType, optional: true)
        let txAmount = attr("amountMinorUnits", .integer64AttributeType, defaultValue: 0)
        let txCurrency = attr("currencyCode", .stringAttributeType, defaultValue: "USD")
        let txCategory = attr("categoryId", .stringAttributeType, optional: true)
        let txNote = attr("note", .stringAttributeType, optional: true)
        let txDate = attr("date", .dateAttributeType, optional: true)
        let txRecurring = attr("isRecurring", .booleanAttributeType, defaultValue: false)
        let txRecurringRuleId = attr("recurringRuleId", .UUIDAttributeType, optional: true)
        let txCreated = attr("createdAt", .dateAttributeType, optional: true)
        let txUpdated = attr("updatedAt", .dateAttributeType, optional: true)
        let txModifiedBy = attr("lastModifiedBy", .stringAttributeType, optional: true)

        // --- GoalEntity ---
        let goalEntity = NSEntityDescription()
        goalEntity.name = "GoalEntity"
        goalEntity.managedObjectClassName = "GoalEntity"

        let goalId = attr("id", .UUIDAttributeType, optional: true)
        let goalName = attr("name", .stringAttributeType, defaultValue: "")
        let goalTarget = attr("targetAmountMinorUnits", .integer64AttributeType, defaultValue: 0)
        let goalCurrent = attr("currentAmountMinorUnits", .integer64AttributeType, defaultValue: 0)
        let goalCurrency = attr("currencyCode", .stringAttributeType, defaultValue: "USD")
        let goalTargetDate = attr("targetDate", .dateAttributeType, optional: true)
        let goalRate = attr("annualInterestRate", .decimalAttributeType, optional: true)
        let goalCompounding = attr("compoundingFrequency", .stringAttributeType, defaultValue: "monthly")
        let goalMonthly = attr("monthlyContributionMinorUnits", .integer64AttributeType, defaultValue: 0)
        let goalIcon = attr("iconName", .stringAttributeType, defaultValue: "star.fill")
        let goalColor = attr("colorHex", .stringAttributeType, defaultValue: "4ECDC4")
        let goalSort = attr("sortOrder", .integer32AttributeType, defaultValue: 0)
        let goalArchived = attr("isArchived", .booleanAttributeType, defaultValue: false)
        let goalSharing = attr("sharingLevel", .stringAttributeType, defaultValue: "private")
        let goalSharedWith = attr("sharedWithMemberIds", .stringAttributeType, optional: true)
        let goalCreated = attr("createdAt", .dateAttributeType, optional: true)
        let goalUpdated = attr("updatedAt", .dateAttributeType, optional: true)
        let goalModifiedBy = attr("lastModifiedBy", .stringAttributeType, optional: true)

        // --- RecurringRuleEntity ---
        let recurringEntity = NSEntityDescription()
        recurringEntity.name = "RecurringRuleEntity"
        recurringEntity.managedObjectClassName = "RecurringRuleEntity"

        let rrId = attr("id", .UUIDAttributeType, optional: true)
        let rrAmount = attr("templateAmountMinorUnits", .integer64AttributeType, defaultValue: 0)
        let rrCurrency = attr("currencyCode", .stringAttributeType, defaultValue: "USD")
        let rrCategory = attr("categoryId", .stringAttributeType, optional: true)
        let rrNote = attr("note", .stringAttributeType, optional: true)
        let rrFreq = attr("frequency", .stringAttributeType, defaultValue: "monthly")
        let rrDayOfMonth = attr("dayOfMonth", .integer16AttributeType, optional: true)
        let rrDayOfWeek = attr("dayOfWeek", .integer16AttributeType, optional: true)
        let rrNextDue = attr("nextDueDate", .dateAttributeType, optional: true)
        let rrActive = attr("isActive", .booleanAttributeType, defaultValue: true)

        // --- Set properties ---
        accountEntity.properties = [
            accountId, accountName, accountType, accountCurrency, accountBalance,
            accountIcon, accountColor, accountSort, accountArchived,
            accountCreated, accountUpdated, accountModifiedBy,
            accountRate, accountExpectedReturn, accountTicker
        ]

        transactionEntity.properties = [
            txId, txAmount, txCurrency, txCategory, txNote, txDate,
            txRecurring, txRecurringRuleId, txCreated, txUpdated, txModifiedBy
        ]

        goalEntity.properties = [
            goalId, goalName, goalTarget, goalCurrent, goalCurrency,
            goalTargetDate, goalRate, goalCompounding, goalMonthly,
            goalIcon, goalColor, goalSort, goalArchived,
            goalSharing, goalSharedWith, goalCreated, goalUpdated, goalModifiedBy
        ]

        recurringEntity.properties = [
            rrId, rrAmount, rrCurrency, rrCategory, rrNote,
            rrFreq, rrDayOfMonth, rrDayOfWeek, rrNextDue, rrActive
        ]

        // --- Relationships ---

        // Account <-> Transactions (one-to-many)
        let accountTransactions = NSRelationshipDescription()
        accountTransactions.name = "transactions"
        accountTransactions.destinationEntity = transactionEntity
        accountTransactions.isOptional = true
        accountTransactions.deleteRule = .cascadeDeleteRule
        accountTransactions.maxCount = 0 // to-many

        let transactionAccount = NSRelationshipDescription()
        transactionAccount.name = "account"
        transactionAccount.destinationEntity = accountEntity
        transactionAccount.isOptional = true
        transactionAccount.deleteRule = .nullifyDeleteRule
        transactionAccount.maxCount = 1

        accountTransactions.inverseRelationship = transactionAccount
        transactionAccount.inverseRelationship = accountTransactions

        // Account <-> Goals (one-to-many)
        let accountGoals = NSRelationshipDescription()
        accountGoals.name = "goals"
        accountGoals.destinationEntity = goalEntity
        accountGoals.isOptional = true
        accountGoals.deleteRule = .nullifyDeleteRule
        accountGoals.maxCount = 0

        let goalAccount = NSRelationshipDescription()
        goalAccount.name = "account"
        goalAccount.destinationEntity = accountEntity
        goalAccount.isOptional = true
        goalAccount.deleteRule = .nullifyDeleteRule
        goalAccount.maxCount = 1

        accountGoals.inverseRelationship = goalAccount
        goalAccount.inverseRelationship = accountGoals

        // Goal <-> Deposits (one-to-many TransactionEntity)
        let goalDeposits = NSRelationshipDescription()
        goalDeposits.name = "deposits"
        goalDeposits.destinationEntity = transactionEntity
        goalDeposits.isOptional = true
        goalDeposits.deleteRule = .cascadeDeleteRule
        goalDeposits.maxCount = 0

        let transactionGoal = NSRelationshipDescription()
        transactionGoal.name = "goal"
        transactionGoal.destinationEntity = goalEntity
        transactionGoal.isOptional = true
        transactionGoal.deleteRule = .nullifyDeleteRule
        transactionGoal.maxCount = 1

        goalDeposits.inverseRelationship = transactionGoal
        transactionGoal.inverseRelationship = goalDeposits

        // RecurringRule <-> Account (many-to-one)
        let rrAccount = NSRelationshipDescription()
        rrAccount.name = "account"
        rrAccount.destinationEntity = accountEntity
        rrAccount.isOptional = true
        rrAccount.deleteRule = .nullifyDeleteRule
        rrAccount.maxCount = 1

        let accountRecurring = NSRelationshipDescription()
        accountRecurring.name = "recurringRules"
        accountRecurring.destinationEntity = recurringEntity
        accountRecurring.isOptional = true
        accountRecurring.deleteRule = .cascadeDeleteRule
        accountRecurring.maxCount = 0

        rrAccount.inverseRelationship = accountRecurring
        accountRecurring.inverseRelationship = rrAccount

        // RecurringRule <-> Transactions (one-to-many)
        let rrTransactions = NSRelationshipDescription()
        rrTransactions.name = "transactions"
        rrTransactions.destinationEntity = transactionEntity
        rrTransactions.isOptional = true
        rrTransactions.deleteRule = .nullifyDeleteRule
        rrTransactions.maxCount = 0

        let txRecurringRule = NSRelationshipDescription()
        txRecurringRule.name = "recurringRule"
        txRecurringRule.destinationEntity = recurringEntity
        txRecurringRule.isOptional = true
        txRecurringRule.deleteRule = .nullifyDeleteRule
        txRecurringRule.maxCount = 1

        rrTransactions.inverseRelationship = txRecurringRule
        txRecurringRule.inverseRelationship = rrTransactions

        // Append relationships to entities
        accountEntity.properties += [accountTransactions, accountGoals, accountRecurring]
        transactionEntity.properties += [transactionAccount, transactionGoal, txRecurringRule]
        goalEntity.properties += [goalAccount, goalDeposits]
        recurringEntity.properties += [rrAccount, rrTransactions]

        model.entities = [accountEntity, transactionEntity, goalEntity, recurringEntity]
        return model
    }

    // MARK: - Attribute Helper

    private static func attr(
        _ name: String,
        _ type: NSAttributeType,
        defaultValue: Any? = nil,
        optional: Bool = false
    ) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        if let defaultValue {
            attr.defaultValue = defaultValue
        }
        return attr
    }
}
