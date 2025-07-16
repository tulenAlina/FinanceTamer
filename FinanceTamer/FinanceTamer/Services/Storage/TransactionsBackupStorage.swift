import Foundation

enum BackupOperationType: String, Codable {
    case create, update, delete
}

struct BackupOperation: Identifiable, Codable {
    let id: Int
    let type: BackupOperationType
    let transaction: TransactionResponse
}

protocol TransactionsBackupStorage {
    func getAllBackupOperations() async throws -> [BackupOperation]
    func addBackupOperation(_ op: BackupOperation) async throws
    func removeBackupOperation(id: Int) async throws
}
