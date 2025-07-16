import Foundation

/// Модель банковского счета, соответствующая API
struct BankAccount: Identifiable, Codable {
    let id: Int
    let userId: Int?
    let name: String
    let balance: String
    let currency: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, userId, name, balance, currency, createdAt, updatedAt
    }
}
