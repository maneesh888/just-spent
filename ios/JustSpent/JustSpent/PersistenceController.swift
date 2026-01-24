import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews
        let sampleExpense = Expense(context: viewContext)
        sampleExpense.id = UUID()
        sampleExpense.amount = NSDecimalNumber(value: 15.99)
        sampleExpense.currency = "USD"
        sampleExpense.category = "Food & Dining"
        sampleExpense.merchant = "Coffee Shop"
        sampleExpense.transactionDate = Date()
        sampleExpense.createdAt = Date()
        sampleExpense.updatedAt = Date()
        sampleExpense.source = "voice_siri"
        sampleExpense.status = "active"
        sampleExpense.isRecurring = false
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
        self.container.viewContext.automaticallyMergesChangesFromParent = true
    }

    init(inMemory: Bool = false, completion: ((NSManagedObjectContext) -> Void)? = nil) {
        let container = NSPersistentContainer(name: "JustSpent")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        let semaphore = DispatchSemaphore(value: 0)
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 2.0) // 2s timeout to prevent infinite deadlock

        // Execute completion handler if provided
        if let completion = completion {
            DispatchQueue.main.async {
                completion(container.viewContext)
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        self.container = container
    }
    
    static func loadAsync(inMemory: Bool = false, completion: @escaping (PersistenceController) -> Void) {
        let container = NSPersistentContainer(name: "JustSpent")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            DispatchQueue.main.async {
                let controller = PersistenceController(container: container)
                completion(controller)
            }
        }
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}