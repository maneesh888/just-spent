import Foundation
import CoreData
import Combine

protocol ExpenseRepositoryProtocol {
    func getAllExpenses() -> AnyPublisher<[Expense], Error>
    func getExpensesByCategory(_ category: String) -> AnyPublisher<[Expense], Error>
    func addExpense(_ expense: ExpenseData) async throws -> Expense
    func deleteExpense(_ expense: Expense) async throws

    // Pagination methods
    func loadExpensesPage(currency: String, dateFilter: DateFilter, page: Int, pageSize: Int) async throws -> [Expense]
}

struct ExpenseData {
    let amount: NSDecimalNumber
    let currency: String
    let category: String
    let merchant: String?
    let notes: String?
    let transactionDate: Date
    let source: String
    let voiceTranscript: String?
}

class ExpenseRepository: ObservableObject, ExpenseRepositoryProtocol {
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    private var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    func getAllExpenses() -> AnyPublisher<[Expense], Error> {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Expense.transactionDate, ascending: false)]
        
        return Publishers.CoreDataPublisher(request: request, context: viewContext)
            .eraseToAnyPublisher()
    }
    
    func getExpensesByCategory(_ category: String) -> AnyPublisher<[Expense], Error> {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Expense.transactionDate, ascending: false)]
        
        return Publishers.CoreDataPublisher(request: request, context: viewContext)
            .eraseToAnyPublisher()
    }
    
    @MainActor
    func addExpense(_ expenseData: ExpenseData) async throws -> Expense {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    let expense = Expense(context: self.viewContext)
                    expense.id = UUID()
                    expense.amount = expenseData.amount
                    expense.currency = expenseData.currency
                    expense.category = expenseData.category
                    expense.merchant = expenseData.merchant
                    expense.notes = expenseData.notes
                    expense.transactionDate = expenseData.transactionDate
                    expense.source = expenseData.source
                    expense.voiceTranscript = expenseData.voiceTranscript
                    expense.status = "active"
                    expense.isRecurring = false
                    expense.createdAt = Date()
                    expense.updatedAt = Date()
                    
                    try self.viewContext.save()
                    continuation.resume(returning: expense)
                } catch {
                    continuation.resume(throwing: ExpenseError.databaseError(error.localizedDescription))
                }
            }
        }
    }
    
    @MainActor
    func deleteExpense(_ expense: Expense) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    self.viewContext.delete(expense)
                    try self.viewContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: ExpenseError.databaseError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Pagination
    @MainActor
    func loadExpensesPage(currency: String, dateFilter: DateFilter, page: Int, pageSize: Int) async throws -> [Expense] {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    let request: NSFetchRequest<Expense> = Expense.fetchRequest()

                    // Currency filter
                    var predicates: [NSPredicate] = [
                        NSPredicate(format: "currency == %@", currency)
                    ]

                    // Date filter (if not .all)
                    if let datePredicate = DateFilterUtils().predicate(for: dateFilter, dateKeyPath: "transactionDate") {
                        predicates.append(datePredicate)
                    }

                    // Combine predicates
                    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

                    // Sort by transaction date (newest first)
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \Expense.transactionDate, ascending: false)]

                    // Pagination
                    request.fetchLimit = pageSize
                    request.fetchOffset = page * pageSize

                    // Execute fetch
                    let expenses = try self.viewContext.fetch(request)
                    continuation.resume(returning: expenses)
                } catch {
                    continuation.resume(throwing: ExpenseError.databaseError(error.localizedDescription))
                }
            }
        }
    }
}

// MARK: - Core Data Publisher
extension Publishers {
    struct CoreDataPublisher<Entity: NSManagedObject>: Publisher {
        typealias Output = [Entity]
        typealias Failure = Error
        
        let request: NSFetchRequest<Entity>
        let context: NSManagedObjectContext
        
        func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = CoreDataSubscription(
                subscriber: subscriber,
                request: request,
                context: context
            )
            subscriber.receive(subscription: subscription)
        }
    }
    
    class CoreDataSubscription<Entity: NSManagedObject, S: Subscriber>: NSObject, Subscription, NSFetchedResultsControllerDelegate where S.Input == [Entity], S.Failure == Error {
        
        private var subscriber: S?
        private let request: NSFetchRequest<Entity>
        private let context: NSManagedObjectContext
        private var fetchedResultsController: NSFetchedResultsController<Entity>?
        
        init(subscriber: S, request: NSFetchRequest<Entity>, context: NSManagedObjectContext) {
            self.subscriber = subscriber
            self.request = request
            self.context = context
            super.init()
            
            fetchedResultsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            fetchedResultsController?.delegate = self
            
            do {
                try fetchedResultsController?.performFetch()
                if let objects = fetchedResultsController?.fetchedObjects {
                    _ = subscriber.receive(objects)
                }
            } catch {
                subscriber.receive(completion: .failure(error))
            }
        }
        
        func request(_ demand: Subscribers.Demand) {}
        
        func cancel() {
            subscriber = nil
            fetchedResultsController = nil
        }
        
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            guard let objects = controller.fetchedObjects as? [Entity] else { return }
            _ = subscriber?.receive(objects)
        }
    }
}