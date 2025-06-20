import Foundation

extension Transaction {
    private static let requiredFieldCount = 7
    
    /// Парсит CSV файл в массив транзакций
    /// - Parameter fileURL: URL CSV файла
    /// - Returns: Массив транзакций
    /// - Throws: ParsingError или FileError в случае ошибок
    static func parseCSVFile(at fileURL: URL) throws -> [Transaction] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw FileError.fileNotFound(fileURL.path)
        }
        
        let data = try Data(contentsOf: fileURL)
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw FileError.invalidEncoding
        }
        
        return try parseCSVString(csvString)
    }
    
    /// Парсит строку CSV в массив транзакций
    /// - Parameter csvString: Строка с CSV данными
    /// - Returns: Массив транзакций
    /// - Throws: ParsingError в случае ошибок парсинга
    static func parseCSVString(_ csvString: String) throws -> [Transaction] {
        let lines = csvString.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        
        var transactions: [Transaction] = []
        
        for (index, line) in lines.enumerated() {
            do {
                let transaction = try parseCSVLine(line)
                transactions.append(transaction)
            } catch let error as ParsingError {
                throw ParsingError.lineParseError(line: index + 1, error: error)
            }
        }
        
        return transactions
    }
    
    /// Парсит одну строку CSV в Transaction
    private static func parseCSVLine(_ line: String) throws -> Transaction {
        let components = try parseCSVComponents(line)
        guard components.count >= requiredFieldCount else {
            throw ParsingError.invalidCSVFormat
        }
        
        guard let id = Int(components[0]) else {
            throw ParsingError.missingRequiredField("id")
        }
        
        guard let accountId = Int(components[1]) else {
            throw ParsingError.missingRequiredField("accountId")
        }
        
        guard let categoryId = Int(components[2]) else {
            throw ParsingError.missingRequiredField("categoryId")
        }
        
        guard let amount = Decimal(string: components[3]) else {
            throw ParsingError.invalidAmountFormat(components[3])
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        guard let transactionDate = dateFormatter.date(from: components[4]) else {
            throw ParsingError.invalidDateFormat("transactionDate: \(components[4])")
        }
        
        guard let createdAt = dateFormatter.date(from: components[5]) else {
            throw ParsingError.invalidDateFormat("createdAt: \(components[5])")
        }
        
        guard let updatedAt = dateFormatter.date(from: components[6]) else {
            throw ParsingError.invalidDateFormat("updatedAt: \(components[6])")
        }
        
        let comment = components.count > requiredFieldCount ? components[7] : nil
        
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
    
    /// Разбивает строку CSV на компоненты с учетом кавычек
    private static func parseCSVComponents(_ line: String) throws -> [String] {
        var result = [String]()
        var currentField = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        result.append(currentField)
        
        return result
    }
    
    /// Генерирует CSV строку из массива транзакций
    static func generateCSVString(from transactions: [Transaction]) -> String {
        return transactions.map { $0.csvString }.joined(separator: "\n")
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
            let escapedComment = comment.replacingOccurrences(of: "\"", with: "\"\"")
            components.append("\"\(escapedComment)\"")
        }
        
        return components.joined(separator: ",")
    }
    
    /// Сохраняет транзакции в CSV файл
    static func saveToCSVFile(_ transactions: [Transaction], at fileURL: URL) throws {
        let csvString = generateCSVString(from: transactions)
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}

