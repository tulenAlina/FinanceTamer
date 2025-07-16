import SwiftUI

class CurrencyService: ObservableObject {
    @Published var currentCurrency: Currency {
        didSet {
            UserDefaults.standard.set(currentCurrency.rawValue, forKey: "selectedCurrency")
        }
    }
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedCurrency"),
           let currency = Currency(rawValue: saved) {
            self.currentCurrency = currency
        } else {
            self.currentCurrency = .rub
        }
    }
}
