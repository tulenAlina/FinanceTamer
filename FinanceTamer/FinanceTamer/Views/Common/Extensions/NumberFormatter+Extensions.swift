import Foundation

extension NumberFormatter {
    static var currency: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = CurrencyService.shared.currentCurrency.symbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = ","
        return formatter
    }
}
