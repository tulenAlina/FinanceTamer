enum Currency: String, Codable {
    case rub = "RUB"
    case usd = "USD"
    case eur = "EUR"
}

extension Currency {
    static let allCases: [Currency] = [.rub, .usd, .eur]
}
