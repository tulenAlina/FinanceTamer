import Foundation

extension Transaction {
    /// Парсит JSON-объект в Transaction
    /// - Parameter jsonObject: JSON-объект (Dictionary)
    /// - Returns: Экземпляр Transaction или nil
    static func parse(jsonObject: Any) -> Transaction? {
        guard let dict = jsonObject as? [String: Any],
            let id = dict["id"] as? Int,
            let accountId = dict["accountId"] as? Int,
            let categoryId = dict["categoryId"] as? Int,
            let amountValue = dict["amount"] as? String,
            let transactionDateString = dict["transactionDate"] as? String,
            let createdAtString = dict["createdAt"] as? String,
            let updatedAtString = dict["updatedAt"] as? String else {
                return nil
        }
        
        guard let amount = Decimal(string: amountValue) else {
            return nil
        }
        
        let dateFormatter = ISO8601DateFormatter()
        guard let transactionDate = dateFormatter.date(from: transactionDateString),
            let createdAt = dateFormatter.date(from: createdAtString),
            let updatedAt = dateFormatter.date(from: updatedAtString) else {
                return nil
            }
        
        let comment = dict["comment"] as? String
        
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
    
    /// Возвращает JSON-представление транзакции
    var jsonObject: Any {
        let dateFormatter = ISO8601DateFormatter()
        var dict: [String: Any] = [
            "id": id,
            "accountId": accountId,
            "categoryId": categoryId,
            "amount": amount.description,
            "transactionDate": dateFormatter.string(from: transactionDate),
            "createdAt": dateFormatter.string(from: createdAt),
            "updatedAt": dateFormatter.string(from: updatedAt)
        ]
        
        if let comment = comment {
            dict["comment"] = comment
        }
                
        return dict
    }
}
