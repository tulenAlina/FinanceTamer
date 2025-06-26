import SwiftUI

@MainActor
class ScoreViewModel: ObservableObject {
    private let accountsService = BankAccountsService.shared
    
    @Published var balance: Decimal = 0
    @Published var currency: Currency = .rub
    @Published var balanceString: String = ""
    
    func loadAccount() {
        Task {
            do {
                let account = try await accountsService.getPrimaryAccount(for: 1)
                balance = account.balance
                currency = account.currency
                updateBalanceString()
            } catch {
                print("Error loading account: \(error)")
            }
        }
    }
    
    func saveChanges(balanceString: String) {
        if let newBalance = Decimal(string: balanceString) {
            balance = newBalance
            Task {
                var account = try await accountsService.getPrimaryAccount(for: 1)
                account.balance = balance
                account.currency = currency
                try await accountsService.updateAccount(account)
                updateBalanceString()
            }
        }
    }
    
    private func updateBalanceString() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        balanceString = formatter.string(from: balance as NSDecimalNumber) ?? ""
    }
}
