import Foundation

/// Сервис для работы с транзакциями
final class TransactionsService {
    var mockTransactions: [Transaction] = [
        // Доходы
        Transaction(
            id: 1,
            accountId: 1,
            categoryId: 1, // Зарплата
            amount: Decimal(100000),
            transactionDate: Date(),
            comment: "Зарплата за март",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 2,
            accountId: 1,
            categoryId: 2, // Подарок
            amount: Decimal(5000),
            transactionDate: Date(),
            comment: "Подарок на день рождения",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 3,
            accountId: 1,
            categoryId: 1, // Зарплата
            amount: Decimal(25000),
            transactionDate: Date(),
            comment: "Аванс по проекту",
            createdAt: Date(),
            updatedAt: Date()
        ),
        
        // Расходы - Продукты
        Transaction(
            id: 4,
            accountId: 1,
            categoryId: 3, // Продукты
            amount: Decimal(-3500),
            transactionDate: Date(),
            comment: "Овощи и фрукты",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 5,
            accountId: 1,
            categoryId: 3, // Продукты
            amount: Decimal(-1200),
            transactionDate: Date(),
            comment: "Молоко и хлеб",
            createdAt: Date(),
            updatedAt: Date()
        ),
        
        // Расходы - Кафе
        Transaction(
            id: 6,
            accountId: 1,
            categoryId: 4, // Кафе
            amount: Decimal(-750),
            transactionDate: Date(),
            comment: "Обед с коллегой",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 7,
            accountId: 1,
            categoryId: 4, // Кафе
            amount: Decimal(-450),
            transactionDate: Date(),
            comment: "Утренний кофе",
            createdAt: Date(),
            updatedAt: Date()
        ),
        
        // Расходы - Транспорт
        Transaction(
            id: 8,
            accountId: 1,
            categoryId: 5, // Транспорт
            amount: Decimal(-350),
            transactionDate: Date(),
            comment: "Такси до работы",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 9,
            accountId: 1,
            categoryId: 5, // Транспорт
            amount: Decimal(-600),
            transactionDate: Date(),
            comment: "Заправка автомобиля",
            createdAt: Date(),
            updatedAt: Date()
        ),
        
        // Расходы - Жилье
        Transaction(
            id: 10,
            accountId: 1,
            categoryId: 6, // Жильё
            amount: Decimal(-25000),
            transactionDate: Date(),
            comment: "Аренда квартиры",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 11,
            accountId: 1,
            categoryId: 6, // Жильё
            amount: Decimal(-3500),
            transactionDate: Date(),
            comment: "Коммунальные платежи",
            createdAt: Date(),
            updatedAt: Date()
        ),
        
        // Расходы - Развлечения
        Transaction(
            id: 12,
            accountId: 1,
            categoryId: 7, // Развлечения
            amount: Decimal(-1500),
            transactionDate: Date(),
            comment: "Билеты в кино",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 13,
            accountId: 1,
            categoryId: 7, // Развлечения
            amount: Decimal(-3000),
            transactionDate: Date(),
            comment: "Концерт любимой группы",
            createdAt: Date(),
            updatedAt: Date()
        ),
        
        // Дополнительные разнообразные транзакции
        Transaction(
            id: 14,
            accountId: 1,
            categoryId: 2, // Подарок
            amount: Decimal(3000),
            transactionDate: Date(),
            comment: "Возврат долга",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 15,
            accountId: 1,
            categoryId: 4, // Кафе
            amount: Decimal(-1200),
            transactionDate: Date(),
            comment: "Ужин в ресторане",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 16,
            accountId: 1,
            categoryId: 3, // Продукты
            amount: Decimal(-2500),
            transactionDate: Date(),
            comment: "Мясо и рыба",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 17,
            accountId: 1,
            categoryId: 5, // Транспорт
            amount: Decimal(-500),
            transactionDate: Date(),
            comment: "Каршеринг",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 18,
            accountId: 1,
            categoryId: 7, // Развлечения
            amount: Decimal(-2000),
            transactionDate: Date(),
            comment: "Музей современного искусства",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 19,
            accountId: 1,
            categoryId: 1, // Зарплата
            amount: Decimal(15000),
            transactionDate: Date(),
            comment: "Фриланс-проект",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 20,
            accountId: 1,
            categoryId: 6, // Жильё
            amount: Decimal(-800),
            transactionDate: Date(),
            comment: "Хозтовары",
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    private let cache: TransactionsFileCache
    private var nextId = 1
    private var isLoaded = false
    
    init(cache: TransactionsFileCache = try! TransactionsFileCache()) {
        self.cache = cache
    }
        
    private func ensureLoaded() async throws {
        guard !isLoaded else { return }
        try await cache.loadFromFile()
        nextId = (cache.transactions.map { $0.id }.max() ?? 0) + 1
        isLoaded = true
    }
    
    /// Загружает транзакции из файла
    func loadTransactions() async throws {
        try await ensureLoaded()
        try await cache.loadFromFile()
        nextId = (cache.transactions.map { $0.id }.max() ?? 0) + 1
    }
    
    /// Получает транзакции за период
    func getTransactions(for period: ClosedRange<Date>) async throws -> [Transaction] {
        try await ensureLoaded()
        try await Task.sleep(nanoseconds: 500_000_000) // Имитация задержки
        return cache.transactions.filter { period.contains($0.transactionDate) }
    }
    func getTransactions(for period: DateInterval) async throws -> [Transaction] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return mockTransactions.filter { transaction in
            period.contains(transaction.transactionDate)
        }
    }
    /// Создает новую транзакцию
    func createTransaction(
        accountId: Int,
        amount: Decimal,
        transactionDate: Date,
        categoryId: Int,
        comment: String?
    ) async throws -> Transaction {
        try await ensureLoaded()
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
        try await cache.addTransaction(transaction)
        return transaction
    }
    
    /// Обновляет существующую транзакцию
    func updateTransaction(_ transaction: Transaction) async throws {
        try await ensureLoaded()
        try await Task.sleep(nanoseconds: 500_000_000) // Имитация задержки
        try await cache.addTransaction(transaction)
    }
    
    /// Удаляет транзакцию по ID
    func deleteTransaction(withId id: Int) async throws {
        try await ensureLoaded()
        try await Task.sleep(nanoseconds: 500_000_000) // Имитация задержки
        try await cache.removeTransaction(withId: id)
    }
}
