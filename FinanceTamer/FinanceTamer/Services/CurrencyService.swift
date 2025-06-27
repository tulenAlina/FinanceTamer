import SwiftUI

class CurrencyService: ObservableObject {
    @Published var currentCurrency: Currency = .rub
    
    static let shared = CurrencyService()
    private init() {}
}
