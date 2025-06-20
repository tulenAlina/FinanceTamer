
import Foundation

/// Кэш для хранения транзакций в JSON-файле
final class TransactionsFileCache {
    // MARK: - Properties
    
    private(set) var transactions: [Transaction] = []
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.financetamer.transactionsCache", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init(filename: String = "transactions") {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsDirectory.appendingPathComponent("\(filename).json")
    }
    
    // MARK: - Public Methods
    
    /// Добавляет или обновляет транзакцию
    func addTransaction(_ transaction: Transaction) throws {
        try queue.sync {
            if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
                transactions[index] = transaction
            } else {
                transactions.append(transaction)
            }
            try saveToFile()
        }
    }
    
    /// Удаляет транзакцию по ID
    func removeTransaction(withId id: Int) throws {
        try queue.sync {
            transactions.removeAll { $0.id == id }
            try saveToFile()
        }
    }
    
    /// Сохраняет все транзакции в файл
    func saveToFile() throws {
        let jsonObjects = transactions.map { $0.jsonObject }
        let data = try JSONSerialization.data(withJSONObject: jsonObjects, options: .prettyPrinted)
        try data.write(to: fileURL, options: .atomic)
    }
    
    /// Загружает транзакции из файла
    func loadFromFile() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            transactions = []
            return
        }
        
        let data = try Data(contentsOf: fileURL)
        let jsonObjects = try JSONSerialization.jsonObject(with: data) as? [Any] ?? []
        
        transactions = jsonObjects.compactMap { Transaction.parse(jsonObject: $0) }
    }
}
