import Foundation

// MARK: - AccountBrief для TransactionResponse
struct AccountBrief: Decodable, Equatable {
    let id: Int
    let name: String
    let balance: String
    let currency: String
}

// MARK: - TransactionRequest (для создания/обновления)
struct TransactionRequest: Encodable {
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: String
    let comment: String?
}

// MARK: - TransactionResponse (ответ API)
struct TransactionResponse: Decodable, Identifiable, Equatable {
    let id: Int
    let account: AccountBrief
    let category: Category
    let amount: String
    let transactionDate: String
    let comment: String?
    let createdAt: String
    let updatedAt: String
}

