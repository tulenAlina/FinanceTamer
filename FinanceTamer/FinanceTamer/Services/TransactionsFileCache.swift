import Foundation

/// Кэш для хранения транзакций в JSON-файле с использованием async/await
final class TransactionsFileCache {
    // MARK: - Properties
    
    private(set) var transactions: [Transaction] = []
    private let fileURL: URL
    
    // MARK: - Initialization
    
    init(filename: String = "transactions") throws {
            guard let supportDir = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                throw FileError.directoryUnavailable
            }
            
            self.fileURL = supportDir.appendingPathComponent("\(filename).json")
            
            // Создание директории, если нужно
            if !FileManager.default.fileExists(atPath: supportDir.path) {
                try FileManager.default.createDirectory(
                    at: supportDir,
                    withIntermediateDirectories: true
                )
            }
        }
    
    // MARK: - Public Methods
    
    /// Добавляет или обновляет транзакцию
    func addTransaction(_ transaction: Transaction) async throws {
        try await Task {
            if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
                transactions[index] = transaction
            } else {
                transactions.append(transaction)
            }
            try await saveToFile()
        }.value
    }
    
    /// Удаляет транзакцию по ID
    func removeTransaction(withId id: Int) async throws {
        try await Task {
            transactions.removeAll { $0.id == id }
            try await saveToFile()
        }.value
    }
    
    /// Сохраняет все транзакции в файл
    func saveToFile() async throws {
        let jsonObjects = transactions.map { $0.jsonObject }
        let data = try JSONSerialization.data(withJSONObject: jsonObjects, options: .prettyPrinted)
        try await writeDataToFile(data)
    }
    
    /// Загружает транзакции из файла
    func loadFromFile() async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // Создаем тестовые данные при первом запуске
            let today = Date()
            let calendar = Calendar.current
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            
            transactions = TransactionsService().mockTransactions
            try await saveToFile()
            return
        }
        
        do {
            let data = try await readDataFromFile()
            let jsonObjects = try JSONSerialization.jsonObject(with: data) as? [Any] ?? []
            transactions = try jsonObjects.map { try Transaction.parse(jsonObject: $0) }
        } catch {
            transactions = []
            throw error
        }
    }
    
    // MARK: - Private Helpers
    
    private func writeDataToFile(_ data: Data) async throws {
        try await Task.detached(priority: .utility) {
            try data.write(to: self.fileURL, options: .atomic)
        }.value
    }
    
    private func readDataFromFile() async throws -> Data {
        try await Task.detached(priority: .utility) {
            try Data(contentsOf: self.fileURL)
        }.value
    }
}
