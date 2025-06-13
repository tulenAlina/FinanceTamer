import Foundation

/// Сервис для работы с транзакциями
final class TransactionsService {
    private let cache: TransactionsFileCache
    private var nextId = 1
    
    init(cache: TransactionsFileCache = TransactionsFileCache()) {
        self.cache = cache
        try? cache.loadFromFile()
        nextId = (cache.transactions.map { $0.id }.max() ?? 0) + 1
    }
    
    /// Получает транзакции за период
    func getTransactions(for period: ClosedRange<Date>) async throws -> [Transaction] {
        try await Task.sleep(nanoseconds: 500_000_000) // Имитация задержки
        return cache.transactions.filter { period.contains($0.transactionDate) }
    }
    
    /// Создает новую транзакцию
    func createTransaction(
        accountId: Int,
        amount: Decimal,
        transactionDate: Date,
        categoryId: Int,
        comment: String?
    ) async throws -> Transaction {
        try await Task.sleep(nanoseconds: 500_000_000) // Имитация задержки
        let transaction = Transaction(
            id: nextId,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: Date(),
            updatedAt: Date()
        )
        nextId += 1
        try cache.addTransaction(transaction)
        return transaction
    }
    
    /// Обновляет существующую транзакцию
    func updateTransaction(_ transaction: Transaction) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // Имитация задержки
        try cache.addTransaction(transaction)
    }
    
    /// Удаляет транзакцию по ID
    func deleteTransaction(withId id: Int) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // Имитация задержки
        try cache.removeTransaction(withId: id)
    }
}
