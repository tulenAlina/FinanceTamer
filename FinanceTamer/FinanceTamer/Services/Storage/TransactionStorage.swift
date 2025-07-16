import Foundation

protocol TransactionsStorage {
    func getAllTransactions() async throws -> [TransactionResponse]
    func createTransaction(_ transaction: TransactionResponse) async throws
    func updateTransaction(id: Int, with transaction: TransactionResponse) async throws
    func deleteTransaction(id: Int) async throws
} 
