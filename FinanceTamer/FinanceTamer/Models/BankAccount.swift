import Foundation

/// Модель банковского счета
struct BankAccount: Identifiable, Codable {
    // MARK: - Properties
    var id: Int
    var userId: Int
    var name: String
    var balance: Decimal
    var currency: Currency
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId, name, balance, currency, createdAt, updatedAt
    }
    
    // MARK: - Initializers
    init(id: Int, userId: Int, name: String, balance: Decimal, currency: Currency, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.balance = balance
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        
        let stringBalance = try container.decode(String.self, forKey: .balance)
        guard let decimalBalance = Decimal(string: stringBalance) else {
            throw ParsingError.invalidAmountFormat(stringBalance)
        }
        balance = decimalBalance
        
        let currencyString = try container.decode(String.self, forKey: .currency)
        guard let currency = Currency(rawValue: currencyString) else {
            throw ParsingError.invalidDataFormat("Invalid currency: \(currencyString)")
        }
        self.currency = currency
        
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encode(balance.description, forKey: .balance)
        try container.encode(currency.rawValue, forKey: .currency) 
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
