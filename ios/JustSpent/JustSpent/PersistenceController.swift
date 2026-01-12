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

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "JustSpent")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Use semaphore to make store loading synchronous (critical for UI testing)
        // This ensures test data can be saved immediately after app initialization
        let semaphore = DispatchSemaphore(value: 0)
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            semaphore.signal()
        }
        semaphore.wait()

        container.viewContext.automaticallyMergesChangesFromParent = true
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