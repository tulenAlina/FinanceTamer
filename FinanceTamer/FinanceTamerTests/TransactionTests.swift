import XCTest
@testable import FinanceTamer

class TransactionTests: XCTestCase {
    let testTransaction = Transaction(
        id: 1,
        accountId: 2,
        categoryId: 3,
        amount: 100.50,
        transactionDate: Date(),
        comment: "Test transaction",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    // MARK: - JSON Tests
    
    func testJSONParsing() {
        let jsonObject = testTransaction.jsonObject as? [String: Any]
        XCTAssertNotNil(jsonObject)
        
        let parsedTransaction = Transaction.parse(jsonObject: jsonObject!)
        XCTAssertNotNil(parsedTransaction)
        
        XCTAssertEqual(parsedTransaction?.id, testTransaction.id)
        XCTAssertEqual(parsedTransaction?.accountId, testTransaction.accountId)
        XCTAssertEqual(parsedTransaction?.categoryId, testTransaction.categoryId)
        XCTAssertEqual(parsedTransaction?.amount, testTransaction.amount)
        XCTAssertEqual(parsedTransaction?.comment, testTransaction.comment)
    }
    
    func testInvalidJSONParsing() {
        // Неполные данные
        let incompleteData: [String: Any] = [
            "id": 1,
            "accountId": 2,
            "categoryId": 3
        ]
        XCTAssertNil(Transaction.parse(jsonObject: incompleteData))
        
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
        XCTAssertNil(Transaction.parse(jsonObject: wrongTypesData))
        
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
        XCTAssertNil(Transaction.parse(jsonObject: wrongDateData))
    }
    
    // MARK: - CSV Tests
    
    func testCSVParsing() {
        let csvString = testTransaction.csvString
        let parsedTransaction = Transaction.parse(csvString: csvString)
        XCTAssertNotNil(parsedTransaction)
        
        XCTAssertEqual(parsedTransaction?.id, testTransaction.id)
        XCTAssertEqual(parsedTransaction?.accountId, testTransaction.accountId)
        XCTAssertEqual(parsedTransaction?.categoryId, testTransaction.categoryId)
        XCTAssertEqual(parsedTransaction?.amount, testTransaction.amount)
        XCTAssertEqual(parsedTransaction?.comment, testTransaction.comment)
    }
    
    func testInvalidCSVParsing() {
        // Недостаточно компонентов
        XCTAssertNil(Transaction.parse(csvString: "1,2,3,100.50"))
        
        // Неправильные типы данных
        XCTAssertNil(Transaction.parse(csvString: "one,two,three,hundred,wrong,wrong,wrong"))
        
        // Неправильный формат даты
        XCTAssertNil(Transaction.parse(csvString: "1,2,3,100.50,2023-06-15,2023-06-15,2023-06-15"))
    }
    
    // MARK: - File Cache Tests
    
    func testFileCache() throws {
        let cache = TransactionsFileCache(filename: "test_transactions")
        try cache.addTransaction(testTransaction)
        try cache.saveToFile()
        
        let newCache = TransactionsFileCache(filename: "test_transactions")
        try newCache.loadFromFile()
        
        XCTAssertEqual(newCache.transactions.count, 1)
        XCTAssertEqual(newCache.transactions[0].id, testTransaction.id)
        
        // Очистка
        try newCache.removeTransaction(withId: testTransaction.id)
        try newCache.saveToFile()
    }
}
