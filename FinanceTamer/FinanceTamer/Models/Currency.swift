enum Currency: String, Codable {
    case rub = "RUB"
    case usd = "USD"
    case eur = "EUR"
}

extension Currency {
    static let allCases: [Currency] = [.rub, .usd, .eur]
}

extension Currency {
    var symbol: String {
        switch self {
        case .rub: return "₽"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
}
