import SwiftUI

class CurrencyService: ObservableObject {
    @Published var currentCurrency: Currency = .rub
    
    init() {}
}
