import Foundation

extension Transaction {
    /// Парсит CSV строку в Transaction
    /// - Parameter csvString: Строка в CSV формате
    /// - Returns: Экземпляр Transaction или nil
    static func parse(csvString: String) -> Transaction? {
        let components = csvString.components(separatedBy: ",")
        guard components.count >= 7 else { return nil }
        
        guard let id = Int(components[0]),
              let accountId = Int(components[1]),
              let categoryId = Int(components[2]),
              let amount = Decimal(string: components[3]) else {
            return nil
        }
        
        let dateFormatter = ISO8601DateFormatter()
        guard let transactionDate = dateFormatter.date(from: components[4]),
              let createdAt = dateFormatter.date(from: components[5]),
              let updatedAt = dateFormatter.date(from: components[6]) else {
            return nil
        }
        
        let comment = components.count > 7 ? components[7] : nil
        
        return Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    /// Возвращает CSV-представление транзакции
    var csvString: String {
        let dateFormatter = ISO8601DateFormatter()
        var components = [
            String(id),
            String(accountId),
            String(categoryId),
            amount.description,
            dateFormatter.string(from: transactionDate),
            dateFormatter.string(from: createdAt),
            dateFormatter.string(from: updatedAt)
        ]
        
        if let comment = comment {
            components.append(comment)
        }
        
        return components.joined(separator: ",")
    }
}
