import SwiftUI

@MainActor
class ScoreViewModel: ObservableObject {
    private let accountsService = BankAccountsService()
    private let currencyService = CurrencyService()
    
    @Published var balance: Decimal = 0
    @Published var balanceString: String = ""
    @Published var originalBalance: Decimal = 0
    @Published var isInitialLoad = true
    @Published var errorMessage: String?
    
    var currency: Currency {
        get { currencyService.currentCurrency }
        set { currencyService.currentCurrency = newValue }
    }
    
    var currencySymbol: String {
        switch currency {
        case .rub: return "₽"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
    
    func loadAccount() {
        Task {
            do {
                let accounts = try await accountsService.getAllAccounts()
                guard let account = accounts.first else { return }
                
                if let decimalBalance = Decimal(string: account.balance) {
                    balance = decimalBalance
                    originalBalance = decimalBalance
                } else {
                    balance = 0
                    originalBalance = 0
                }
                
                // Загружаем валюту из аккаунта только при первой загрузке
                if isInitialLoad {
                    if let currencyEnum = Currency(rawValue: account.currency) {
                        currency = currencyEnum
                    }
                    isInitialLoad = false
                }
                
                updateBalanceString()
            } catch {
                errorMessage = error.localizedDescription
                print("Error loading account: \(error)")
            }
        }
    }
    
    func saveChanges(balanceString: String) {
        let cleanedString = balanceString.replacingOccurrences(of: ",", with: ".")
        
        if let newBalance = Decimal(string: cleanedString) {
            // Проверяем, изменилось ли значение
            guard newBalance != originalBalance else {
                print("Значение не изменилось, сохранение не требуется")
                return
            }
            
            balance = newBalance
            Task {
                let accounts = try await accountsService.getAllAccounts()
                guard let account = accounts.first else { return }
                let request = BankAccountsService.AccountUpdateRequest(
                    name: account.name,
                    balance: String(format: "%.2f", NSDecimalNumber(decimal: balance).doubleValue),
                    currency: currency.rawValue
                )
                _ = try await accountsService.updateAccount(id: account.id, request: request)
                originalBalance = balance // Обновляем исходное значение
                updateBalanceString()
            }
        }
    }
    
    private func updateBalanceString() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2  // Ограничиваем до 2 знаков после запятой
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = ","    // Используем запятую как разделитель
        formatter.groupingSeparator = " "   // Разделитель тысяч
        balanceString = formatter.string(from: balance as NSDecimalNumber) ?? ""
    }
    
    func refreshAccount() async {
        await loadAccount()
    }
}
