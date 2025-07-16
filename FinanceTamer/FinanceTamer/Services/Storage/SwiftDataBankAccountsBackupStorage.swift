import Foundation
import SwiftData

@Model
final class LocalAccountBackupOperation: Identifiable {
    @Attribute(.unique) var id: Int
    var type: String
    var accountData: Data
    
    init(id: Int, type: String, accountData: Data) {
        self.id = id
        self.type = type
        self.accountData = accountData
    }
    
    func toBackupOperation() -> AccountBackupOperation? {
        guard let account = try? JSONDecoder().decode(BankAccount.self, from: accountData),
              let opType = AccountBackupOperationType(rawValue: type) else { return nil }
        return AccountBackupOperation(id: id, type: opType, account: account)
    }
    
    static func fromBackupOperation(_ op: AccountBackupOperation) -> LocalAccountBackupOperation? {
        guard let data = try? JSONEncoder().encode(op.account) else { return nil }
        return LocalAccountBackupOperation(id: op.id, type: op.type.rawValue, accountData: data)
    }
}

@MainActor
final class SwiftDataBankAccountsBackupStorage: BankAccountsBackupStorage {
    private let container: ModelContainer
    
    init() {
        self.container = try! ModelContainer(for: LocalAccountBackupOperation.self, configurations: ModelConfiguration("accounts_backup"))
    }
    
    func getAllBackupOperations() async throws -> [AccountBackupOperation] {
        let context = container.mainContext
        let locals = try context.fetch(FetchDescriptor<LocalAccountBackupOperation>())
        return locals.compactMap { $0.toBackupOperation() }
    }
    
    func addBackupOperation(_ op: AccountBackupOperation) async throws {
        let context = container.mainContext
        guard let local = LocalAccountBackupOperation.fromBackupOperation(op) else { return }
        context.insert(local)
        try context.save()
    }
    
    func removeBackupOperation(id: Int) async throws {
        let context = container.mainContext
        let fetch = FetchDescriptor<LocalAccountBackupOperation>(predicate: #Predicate { $0.id == id })
        if let local = try context.fetch(fetch).first {
            context.delete(local)
            try context.save()
        }
    }
}
