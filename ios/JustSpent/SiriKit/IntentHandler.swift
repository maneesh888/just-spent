import Intents
import CoreData

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        switch intent {
        case is LogExpenseIntent:
            return LogExpenseIntentHandler()
        case is ViewExpensesIntent:
            return ViewExpensesIntentHandler()
        default:
            fatalError("Unhandled intent type: \(intent)")
        }
    }
}

// MARK: - Log Expense Intent Handler

class LogExpenseIntentHandler: NSObject, LogExpenseIntentHandling {
    
    func handle(intent: LogExpenseIntent, completion: @escaping (LogExpenseIntentResponse) -> Void) {
        // Validate required parameters
        guard let amount = intent.amount,
              amount.doubleValue > 0 else {
            completion(LogExpenseIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        // Create expense data
        let expenseData = ExpenseData(
            amount: amount,
            currency: intent.currency ?? "USD",
            category: mapCategory(intent.category),
            merchant: intent.merchant,
            notes: intent.note,
            transactionDate: Date(),
            source: .voiceSiri,
            voiceTranscript: nil
        )
        
        // Save to shared container
        do {
            let expense = try SharedDataManager.shared.saveExpense(expenseData)
            
            // Create success response
            let response = LogExpenseIntentResponse(code: .success, userActivity: nil)
            response.amount = amount
            response.category = intent.category
            response.merchant = intent.merchant
            
            // Create user activity for handoff
            let userActivity = NSUserActivity(activityType: "com.justspent.logExpense")
            userActivity.title = "Expense Logged"
            userActivity.userInfo = [
                "expenseId": expense.id?.uuidString ?? "",
                "amount": amount.doubleValue,
                "category": mapCategory(intent.category)
            ]
            response.userActivity = userActivity
            
            completion(response)
            
        } catch {
            let response = LogExpenseIntentResponse(code: .failure, userActivity: nil)
            completion(response)
        }
    }
    
    func confirm(intent: LogExpenseIntent, completion: @escaping (LogExpenseIntentResponse) -> Void) {
        // Validate parameters before execution
        guard let amount = intent.amount,
              amount.doubleValue > 0,
              amount.doubleValue <= 999999.99 else {
            completion(LogExpenseIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        completion(LogExpenseIntentResponse(code: .success, userActivity: nil))
    }
    
    // MARK: - Parameter Resolution
    
    func resolveAmount(for intent: LogExpenseIntent, with completion: @escaping (INDecimalNumberResolutionResult) -> Void) {
        guard let amount = intent.amount else {
            completion(.needsValue())
            return
        }
        
        let value = amount.doubleValue
        if value <= 0 {
            completion(.unsupported(forReason: .negativeNumbersNotSupported))
        } else if value > 999999.99 {
            completion(.unsupported(forReason: .greaterThanMaximumValue))
        } else {
            completion(.success(with: amount))
        }
    }
    
    func resolveCategory(for intent: LogExpenseIntent, with completion: @escaping (ExpenseCategoryResolutionResult) -> Void) {
        guard let category = intent.category else {
            completion(.needsValue())
            return
        }
        
        completion(.success(with: category))
    }
    
    func resolveMerchant(for intent: LogExpenseIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        guard let merchant = intent.merchant,
              !merchant.isEmpty else {
            completion(.notRequired())
            return
        }
        
        if merchant.count > 100 {
            completion(.unsupported(forReason: .invalidFormat))
        } else {
            completion(.success(with: merchant))
        }
    }
    
    func resolveNote(for intent: LogExpenseIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        guard let note = intent.note,
              !note.isEmpty else {
            completion(.notRequired())
            return
        }
        
        if note.count > 500 {
            completion(.unsupported(forReason: .invalidFormat))
        } else {
            completion(.success(with: note))
        }
    }
    
    func resolveCurrency(for intent: LogExpenseIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        let currencyString = intent.currency ?? "USD"

        // Try to detect currency from string using Currency model
        if let detectedCurrency = Currency.detectFromText(currencyString) {
            completion(.success(with: detectedCurrency.rawValue))
        } else if let validCurrency = Currency.from(isoCode: currencyString) {
            // Valid ISO code provided
            completion(.success(with: validCurrency.rawValue))
        } else {
            // Fallback to user's default currency or USD
            let defaultCurrency = UserPreferences.shared.getCurrentCurrency()
            completion(.success(with: defaultCurrency.rawValue))
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapCategory(_ category: ExpenseCategory?) -> String {
        guard let category = category else { return "Other" }
        
        switch category {
        case .foodDining:
            return "Food & Dining"
        case .grocery:
            return "Grocery"
        case .transportation:
            return "Transportation"
        case .shopping:
            return "Shopping"
        case .entertainment:
            return "Entertainment"
        case .billsUtilities:
            return "Bills & Utilities"
        case .healthcare:
            return "Healthcare"
        case .education:
            return "Education"
        case .other:
            return "Other"
        case .unknown:
            return "Other"
        @unknown default:
            return "Other"
        }
    }
}

// MARK: - View Expenses Intent Handler

class ViewExpensesIntentHandler: NSObject, ViewExpensesIntentHandling {
    
    func handle(intent: ViewExpensesIntent, completion: @escaping (ViewExpensesIntentResponse) -> Void) {
        // Fetch expenses from shared container
        do {
            let expenses = try SharedDataManager.shared.fetchExpenses(
                category: mapCategory(intent.category),
                timePeriod: intent.timePeriod
            )
            
            let response = ViewExpensesIntentResponse(code: .success, userActivity: nil)
            
            // Create summary information
            let totalAmount = expenses.reduce(0) { $0 + ($1.amount?.doubleValue ?? 0) }
            let expenseCount = expenses.count
            
            // Create user activity for handoff
            let userActivity = NSUserActivity(activityType: "com.justspent.viewExpenses")
            userActivity.title = "View Expenses"
            userActivity.userInfo = [
                "category": mapCategory(intent.category) ?? "All",
                "timePeriod": intent.timePeriod ?? "All Time",
                "totalAmount": totalAmount,
                "expenseCount": expenseCount
            ]
            response.userActivity = userActivity
            
            completion(response)
            
        } catch {
            completion(ViewExpensesIntentResponse(code: .failure, userActivity: nil))
        }
    }
    
    func confirm(intent: ViewExpensesIntent, completion: @escaping (ViewExpensesIntentResponse) -> Void) {
        completion(ViewExpensesIntentResponse(code: .success, userActivity: nil))
    }
    
    // MARK: - Parameter Resolution
    
    func resolveCategory(for intent: ViewExpensesIntent, with completion: @escaping (ExpenseCategoryResolutionResult) -> Void) {
        if let category = intent.category {
            completion(.success(with: category))
        } else {
            completion(.notRequired())
        }
    }
    
    func resolveTimePeriod(for intent: ViewExpensesIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        guard let timePeriod = intent.timePeriod else {
            completion(.notRequired())
            return
        }
        
        let validPeriods = ["today", "this week", "this month", "this year", "all time"]
        let normalizedPeriod = timePeriod.lowercased()
        
        if validPeriods.contains(normalizedPeriod) {
            completion(.success(with: normalizedPeriod))
        } else {
            completion(.success(with: "all time")) // Default
        }
    }
    
    private func mapCategory(_ category: ExpenseCategory?) -> String? {
        guard let category = category else { return nil }
        
        switch category {
        case .foodDining:
            return "Food & Dining"
        case .grocery:
            return "Grocery"
        case .transportation:
            return "Transportation"
        case .shopping:
            return "Shopping"
        case .entertainment:
            return "Entertainment"
        case .billsUtilities:
            return "Bills & Utilities"
        case .healthcare:
            return "Healthcare"
        case .education:
            return "Education"
        case .other:
            return "Other"
        case .unknown:
            return "Other"
        @unknown default:
            return "Other"
        }
    }
}

// MARK: - Shared Data Manager

class SharedDataManager {
    static let shared = SharedDataManager()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "JustSpent")
        
        // Use shared container for app group
        let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.justspent.shared")!
            .appendingPathComponent("JustSpent.sqlite")
        
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        return container
    }()
    
    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveExpense(_ expenseData: ExpenseData) throws -> Expense {
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.amount = NSDecimalNumber(value: expenseData.amount.doubleValue)
        expense.currency = expenseData.currency
        expense.category = expenseData.category
        expense.merchant = expenseData.merchant
        expense.expenseDescription = expenseData.notes
        expense.transactionDate = expenseData.transactionDate
        expense.source = expenseData.source.rawValue
        expense.voiceTranscript = expenseData.voiceTranscript
        expense.createdAt = Date()
        expense.updatedAt = Date()
        
        try context.save()
        return expense
    }
    
    func fetchExpenses(category: String?, timePeriod: String?) throws -> [Expense] {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        var predicates: [NSPredicate] = []
        
        // Filter by category if specified
        if let category = category, category != "All" {
            predicates.append(NSPredicate(format: "category == %@", category))
        }
        
        // Filter by time period if specified
        if let timePeriod = timePeriod {
            let calendar = Calendar.current
            let now = Date()
            
            switch timePeriod.lowercased() {
            case "today":
                let startOfDay = calendar.startOfDay(for: now)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                predicates.append(NSPredicate(format: "transactionDate >= %@ AND transactionDate < %@", startOfDay as NSDate, endOfDay as NSDate))
                
            case "this week":
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
                predicates.append(NSPredicate(format: "transactionDate >= %@ AND transactionDate < %@", startOfWeek as NSDate, endOfWeek as NSDate))
                
            case "this month":
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
                predicates.append(NSPredicate(format: "transactionDate >= %@ AND transactionDate < %@", startOfMonth as NSDate, endOfMonth as NSDate))
                
            case "this year":
                let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
                let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear)!
                predicates.append(NSPredicate(format: "transactionDate >= %@ AND transactionDate < %@", startOfYear as NSDate, endOfYear as NSDate))
                
            default:
                break // No time filter for "all time"
            }
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Expense.transactionDate, ascending: false)]
        
        return try context.fetch(request)
    }
}

// MARK: - Supporting Types

enum ExpenseSource: String, CaseIterable {
    case manual = "manual"
    case voiceSiri = "voice_siri"
    case voiceAssistant = "voice_assistant"
    case import = "import"
    case recurring = "recurring"
    case api = "api"
    case quickAdd = "quick_add"
}

struct ExpenseData {
    let amount: NSDecimalNumber
    let currency: String
    let category: String
    let merchant: String?
    let notes: String?
    let transactionDate: Date
    let source: ExpenseSource
    let voiceTranscript: String?
}