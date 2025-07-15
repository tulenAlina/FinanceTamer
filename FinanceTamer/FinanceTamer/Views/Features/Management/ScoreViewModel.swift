import SwiftUI

@MainActor
class ScoreViewModel: ObservableObject {
    private let accountsService = BankAccountsService()
    private let currencyService = CurrencyService()
    private let transactionsService = TransactionsService()
    
    @Published var balance: Decimal = 0
    @Published var balanceString: String = ""
    @Published var originalBalance: Decimal = 0
    @Published var isInitialLoad = true
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var transactions: [TransactionResponse] = []
    private let lastManualBalanceUpdateKey = "lastManualBalanceUpdateKey"
    private(set) var lastManualBalanceUpdate: Date? {
        get {
            if let dateString = UserDefaults.standard.string(forKey: lastManualBalanceUpdateKey) {
                return ISO8601DateFormatter().date(from: dateString)
            }
            return nil
        }
        set {
            if let date = newValue {
                let dateString = ISO8601DateFormatter().string(from: date)
                UserDefaults.standard.set(dateString, forKey: lastManualBalanceUpdateKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastManualBalanceUpdateKey)
            }
        }
    }
    
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
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let accounts = try await accountsService.getAllAccounts()
                guard let account = accounts.first else { return }
                let accountId = account.id
                let allTransactions = try await transactionsService.getTransactions(accountId: accountId)
                self.transactions = allTransactions
                var computedBalance = Decimal(string: account.balance) ?? 0
                if let lastManual = lastManualBalanceUpdate {
                    let newTransactions = allTransactions.filter { transaction in
                        let createdAt = ISO8601DateFormatter().date(from: transaction.createdAt) ?? Date.distantPast
                        return createdAt > lastManual
                    }
                    let delta = newTransactions.reduce(Decimal(0)) { result, transaction in
                        let amount = Decimal(string: transaction.amount) ?? 0
                        if transaction.category.direction == .income {
                            return result + amount
                        } else {
                            return result - amount
                        }
                    }
                    computedBalance += delta
                }
                self.balance = computedBalance
                self.originalBalance = computedBalance
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
        isLoading = true
        Task {
            defer { isLoading = false }
            let cleanedString = balanceString.replacingOccurrences(of: ",", with: ".")
            if let newBalance = Decimal(string: cleanedString) {
                guard newBalance != originalBalance else {
                    print("Значение не изменилось, сохранение не требуется")
                    return
                }
                do {
                    let accounts = try await accountsService.getAllAccounts()
                    guard let account = accounts.first else { return }
                    let request = BankAccountsService.AccountUpdateRequest(
                        name: account.name,
                        balance: String(format: "%.2f", NSDecimalNumber(decimal: newBalance).doubleValue),
                        currency: currency.rawValue
                    )
                    _ = try await accountsService.updateAccount(id: account.id, request: request)
                    // После успешного обновления:
                    self.lastManualBalanceUpdate = Date()
                    balance = newBalance
                    originalBalance = newBalance
                    updateBalanceString()
                } catch {
                    errorMessage = error.localizedDescription
                    print("Error saving changes: \(error)")
                }
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
        isLoading = true
        defer { isLoading = false }
        do {
            await loadAccount()
        } catch {
            errorMessage = error.localizedDescription
            print("Error refreshing account: \(error)")
        }
    }
}
