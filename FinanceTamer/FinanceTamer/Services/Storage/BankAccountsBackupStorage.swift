import Foundation

enum AccountBackupOperationType: String, Codable { case update, create, delete }

struct AccountBackupOperation: Identifiable, Codable {
    let id: Int
    let type: AccountBackupOperationType
    let account: BankAccount
}

protocol BankAccountsBackupStorage {
    func getAllBackupOperations() async throws -> [AccountBackupOperation]
    func addBackupOperation(_ op: AccountBackupOperation) async throws
    func removeBackupOperation(id: Int) async throws
}
