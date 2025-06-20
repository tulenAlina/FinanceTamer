import XCTest
@testable import FinanceTamer

class TransactionTests: XCTestCase {
    // MARK: - Test Data
    
    private let dateFormatter = ISO8601DateFormatter()
    private var testTransaction: Transaction!
    
    override func setUp() {
        super.setUp()
        // Используем фиксированную дату для тестов
        let dateString = "2023-06-20T12:00:00Z"
        let date = dateFormatter.date(from: dateString)!
        
        testTransaction = Transaction(
            id: 1,
            accountId: 2,
            categoryId: 3,
            amount: 100.50,
            transactionDate: date,
            comment: "Test transaction",
            createdAt: date,
            updatedAt: date
        )
    }
    
    // MARK: - JSON Tests
    
    func testJSONParsing() throws {
        let jsonObject = testTransaction.jsonObject
        
        let parsedTransaction = try Transaction.parse(jsonObject: jsonObject)
        
        XCTAssertEqual(parsedTransaction.id, testTransaction.id)
        XCTAssertEqual(parsedTransaction.accountId, testTransaction.accountId)
        XCTAssertEqual(parsedTransaction.categoryId, testTransaction.categoryId)
        XCTAssertEqual(parsedTransaction.amount, testTransaction.amount)
        XCTAssertEqual(parsedTransaction.comment, testTransaction.comment)
        XCTAssertEqual(
            dateFormatter.string(from: parsedTransaction.transactionDate),
            dateFormatter.string(from: testTransaction.transactionDate)
        )
    }
    
    func testInvalidJSONParsing() {
        // Неполные данные
        let incompleteData: [String: Any] = [
            "id": 1,
            "accountId": 2,
            "categoryId": 3
        ]
        XCTAssertThrowsError(try Transaction.parse(jsonObject: incompleteData)) { error in
            XCTAssertTrue(error is ParsingError)
        }
        
        // Неправильные типы данных
        let wrongTypesData: [String: Any] = [
            "id": "one",
            "accountId": "two",
            "categoryId": "three",
            "amount": "hundred",
            "transactionDate": "not a date",
            "createdAt": "not a date",
            "updatedAt": "not a date"
        ]
        XCTAssertThrowsError(try Transaction.parse(jsonObject: wrongTypesData)) { error in
            XCTAssertTrue(error is ParsingError)
        }
        
        // Неправильный формат даты
        let wrongDateData: [String: Any] = [
            "id": 1,
            "accountId": 2,
            "categoryId": 3,
            "amount": "100.50",
            "transactionDate": "2023-06-15",
            "createdAt": "2023-06-15",
            "updatedAt": "2023-06-15"
        ]
        XCTAssertThrowsError(try Transaction.parse(jsonObject: wrongDateData)) { error in
            XCTAssertTrue(error is ParsingError)
        }
    }
    
    // MARK: - CSV Tests
    
    func testCSVParsing() throws {
        let csvString = testTransaction.csvString
        let parsedTransactions = try Transaction.parseCSVString(csvString)
        
        XCTAssertEqual(parsedTransactions.count, 1)
        let parsedTransaction = parsedTransactions[0]
        
        XCTAssertEqual(parsedTransaction.id, testTransaction.id)
        XCTAssertEqual(parsedTransaction.accountId, testTransaction.accountId)
        XCTAssertEqual(parsedTransaction.categoryId, testTransaction.categoryId)
        XCTAssertEqual(parsedTransaction.amount, testTransaction.amount)
        XCTAssertEqual(parsedTransaction.comment, testTransaction.comment)
        XCTAssertEqual(
            dateFormatter.string(from: parsedTransaction.transactionDate),
            dateFormatter.string(from: testTransaction.transactionDate)
        )
    }
    
    func testInvalidCSVParsing() {
        // Недостаточно компонентов
        XCTAssertThrowsError(try Transaction.parseCSVString("1,2,3,100.50")) { error in
            XCTAssertTrue(error is ParsingError)
        }
        
        // Неправильные типы данных
        XCTAssertThrowsError(try Transaction.parseCSVString( "one,two,three,hundred,wrong,wrong,wrong")) { error in
            XCTAssertTrue(error is ParsingError)
        }
        
        // Неправильный формат даты
        XCTAssertThrowsError(try Transaction.parseCSVString( "1,2,3,100.50,2023-06-15,2023-06-15,2023-06-15")) { error in
            XCTAssertTrue(error is ParsingError)
        }
    }
    
    func testCSVWithCommaInComment() throws {
        let dateString = "2023-06-20T12:00:00Z"
        let date = dateFormatter.date(from: dateString)!
        
        let transactionWithComment = Transaction(
            id: 1,
            accountId: 2,
            categoryId: 3,
            amount: 100.50,
            transactionDate: date,
            comment: "Test, comment",
            createdAt: date,
            updatedAt: date
        )
        
        let csvString = transactionWithComment.csvString
        print("Generated CSV: \(csvString)")
        
        let parsedTransactions = try Transaction.parseCSVString(csvString)
        XCTAssertEqual(parsedTransactions[0].comment, "Test, comment")
    }

    
    // MARK: - File Cache Tests
    
    func testFileCache() async {
        do {
            let cache = try TransactionsFileCache(filename: "test_transactions")
            try await cache.addTransaction(testTransaction)
            try await cache.saveToFile()

            let newCache = try TransactionsFileCache(filename: "test_transactions")
            try await newCache.loadFromFile()

            XCTAssertEqual(newCache.transactions.count, 1)
            XCTAssertEqual(newCache.transactions[0].id, testTransaction.id)

            // Очистка
            try await newCache.removeTransaction(withId: testTransaction.id)
            try await newCache.saveToFile()
        } catch {
            XCTFail("Ошибка при работе с файловым кэшем: \(error)")
        }
    }
    
    func testCSVFileParsing() throws {
        // Создаем временный файл
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_transactions.csv")
        
        // Записываем тестовые данные
        let testData = testTransaction.csvString
        try testData.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Парсим файл
        let parsedTransactions = try Transaction.parseCSVFile(at: fileURL)
        
        // Проверяем результат
        XCTAssertEqual(parsedTransactions.count, 1)
        XCTAssertEqual(parsedTransactions[0].id, testTransaction.id)
        
        // Удаляем временный файл
        try FileManager.default.removeItem(at: fileURL)
    }

    func testMultipleTransactionsCSV() throws {
        let transaction1 = testTransaction!
        let transaction2 = Transaction(
            id: 2,
            accountId: 3,
            categoryId: 4,
            amount: 200.75,
            transactionDate: Date(),
            comment: "Another, transaction",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let csvString = [transaction1, transaction2].map { $0.csvString }.joined(separator: "\n")
        let parsedTransactions = try Transaction.parseCSVString(csvString)
        
        XCTAssertEqual(parsedTransactions.count, 2)
        XCTAssertEqual(parsedTransactions[1].comment, "Another, transaction")
    }
}
