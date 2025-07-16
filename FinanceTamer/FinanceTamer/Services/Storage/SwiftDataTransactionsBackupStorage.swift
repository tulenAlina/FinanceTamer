import Foundation
import SwiftData

@Model
final class LocalBackupOperation: Identifiable {
    @Attribute(.unique) var id: Int
    var type: String
    var transactionData: Data
    
    init(id: Int, type: String, transactionData: Data) {
        self.id = id
        self.type = type
        self.transactionData = transactionData
    }
    
    func toBackupOperation() -> BackupOperation? {
        guard let transaction = try? JSONDecoder().decode(TransactionResponse.self, from: transactionData),
              let opType = BackupOperationType(rawValue: type) else { return nil }
        return BackupOperation(id: id, type: opType, transaction: transaction)
    }
    
    static func fromBackupOperation(_ op: BackupOperation) -> LocalBackupOperation? {
        guard let data = try? JSONEncoder().encode(op.transaction) else { return nil }
        return LocalBackupOperation(id: op.id, type: op.type.rawValue, transactionData: data)
    }
}

@MainActor
final class SwiftDataTransactionsBackupStorage: TransactionsBackupStorage {
    private let container: ModelContainer
    
    init() {
        self.container = try! ModelContainer(for: LocalBackupOperation.self, configurations: ModelConfiguration("transactions_backup"))
    }
    
    func getAllBackupOperations() async throws -> [BackupOperation] {
        let context = container.mainContext
        let locals = try context.fetch(FetchDescriptor<LocalBackupOperation>())
        return locals.compactMap { $0.toBackupOperation() }
    }
    
    func addBackupOperation(_ op: BackupOperation) async throws {
        let context = container.mainContext
        guard let local = LocalBackupOperation.fromBackupOperation(op) else { return }
        context.insert(local)
        try context.save()
    }
    
    func removeBackupOperation(id: Int) async throws {
        let context = container.mainContext
        let fetch = FetchDescriptor<LocalBackupOperation>(predicate: #Predicate { $0.id == id })
        if let local = try context.fetch(fetch).first {
            context.delete(local)
            try context.save()
        }
    }
}
