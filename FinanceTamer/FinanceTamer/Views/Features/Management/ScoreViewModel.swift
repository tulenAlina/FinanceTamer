import SwiftUI

@MainActor
class ScoreViewModel: ObservableObject {
    private let accountsService = BankAccountsService.shared
    private let currencyService = CurrencyService.shared
    
    @Published var balance: Decimal = 0
    @Published var balanceString: String = ""
    @Published var originalBalance: Decimal = 0
    @Published var isInitialLoad = true
    
    var currency: Currency {
        get { currencyService.currentCurrency }
        set { currencyService.currentCurrency = newValue }
    }
    
    func loadAccount() {
        Task {
            do {
                let account = try await accountsService.getPrimaryAccount(for: 1)
                balance = account.balance
                originalBalance = account.balance
                
                // Загружаем валюту из аккаунта только при первой загрузке
                if isInitialLoad {
                    currency = account.currency
                    isInitialLoad = false
                }
                
                updateBalanceString()
            } catch {
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
                var account = try await accountsService.getPrimaryAccount(for: 1)
                account.balance = balance
                account.currency = currency
                try await accountsService.updateAccount(account)
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
