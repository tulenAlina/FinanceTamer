import Foundation

extension Transaction {
    /// Парсит JSON-объект в Transaction
    /// - Parameter jsonObject: JSON-объект (Dictionary)
    /// - Returns: Экземпляр Transaction
    /// - Throws: ParsingError в случае ошибок парсинга
    static func parse(jsonObject: Any) throws -> Transaction {
        guard let dict = jsonObject as? [String: Any] else {
            throw ParsingError.invalidJSONStructure
        }
        
        guard let id = dict["id"] as? Int else {
            throw ParsingError.missingRequiredField("id")
        }
        
        guard let accountId = dict["accountId"] as? Int else {
            throw ParsingError.missingRequiredField("accountId")
        }
        
        guard let categoryId = dict["categoryId"] as? Int else {
            throw ParsingError.missingRequiredField("categoryId")
        }
        
        guard let amountValue = dict["amount"] as? String else {
            throw ParsingError.missingRequiredField("amount")
        }
        
        guard let transactionDateString = dict["transactionDate"] as? String else {
            throw ParsingError.missingRequiredField("transactionDate")
        }
        
        guard let createdAtString = dict["createdAt"] as? String else {
            throw ParsingError.missingRequiredField("createdAt")
        }
        
        guard let updatedAtString = dict["updatedAt"] as? String else {
            throw ParsingError.missingRequiredField("updatedAt")
        }
        
        guard let amount = Decimal(string: amountValue) else {
            throw ParsingError.invalidAmountFormat(amountValue)
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        guard let transactionDate = dateFormatter.date(from: transactionDateString) else {
            throw ParsingError.invalidDateFormat("transactionDate: \(transactionDateString)")
        }
        
        guard let createdAt = dateFormatter.date(from: createdAtString) else {
            throw ParsingError.invalidDateFormat("createdAt: \(createdAtString)")
        }
        
        guard let updatedAt = dateFormatter.date(from: updatedAtString) else {
            throw ParsingError.invalidDateFormat("updatedAt: \(updatedAtString)")
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
    var jsonObject: [String: Any] {
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
