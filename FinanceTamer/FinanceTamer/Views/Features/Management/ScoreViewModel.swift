import SwiftUI

@MainActor
class ScoreViewModel: ObservableObject {
    private let accountsService = BankAccountsService()
    private let transactionsService = TransactionsService()
    
    @Published var balance: Decimal = 0
    @Published var balanceString: String = ""
    @Published var originalBalance: Decimal = 0
    @Published var isInitialLoad = true
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var transactions: [TransactionResponse] = []
    @Published var balanceHistory: [BalanceData] = []
    
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
    
    func isCancelledError(_ error: Error) -> Bool {
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }
        if let networkError = error as? NetworkError {
            switch networkError {
            case .networkError(let err):
                return isCancelledError(err)
            default:
                return false
            }
        }
        return false
    }
    
    func loadAccount() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let accounts = try await accountsService.getAllAccounts()
                guard let account = accounts.first else { return }
                let accountId = account.id
                
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
                
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withFullDate]
                let startDateString = dateFormatter.string(from: startDate)
                let endDateString = dateFormatter.string(from: endDate)
                
                
                let allTransactions = try await transactionsService.getTransactions(
                    accountId: accountId,
                    startDate: startDateString,
                    endDate: endDateString
                )
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
                    if Currency(rawValue: account.currency) != nil {
                    }
                    isInitialLoad = false
                }
                updateBalanceString()
                calculateBalanceHistory()
            } catch {
                if isCancelledError(error) || Task.isCancelled {
                    return
                }
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
                        currency:
                        account.currency
                    )
                    _ = try await accountsService.updateAccount(id: account.id, request: request)
                    self.lastManualBalanceUpdate = Date()
                    balance = newBalance
                    originalBalance = newBalance
                    updateBalanceString()
                } catch {
                    if isCancelledError(error) || Task.isCancelled {
                        return
                    }
                    errorMessage = error.localizedDescription
                    print("Error saving changes: \(error)")
                }
            }
        }
    }
    
    private func updateBalanceString() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = " "
        balanceString = formatter.string(from: balance as NSDecimalNumber) ?? ""
    }
    
    func refreshAccount() async {
        isLoading = true
        defer { isLoading = false }
        loadAccount()
    }
    
    func calculateBalanceHistory() {
        guard !transactions.isEmpty else {
            balanceHistory = []
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) else {
            balanceHistory = []
            return
        }
        
        var dailyTransactions: [Date: Decimal] = [:]
        
        for transaction in transactions {
            guard let date = ISO8601DateFormatter().date(from: transaction.transactionDate),
                  let amount = Decimal(string: transaction.amount) else {
                continue 
            }
            
            let dayStart = calendar.startOfDay(for: date)
            
            guard dayStart >= thirtyDaysAgo && dayStart <= today else {
                continue 
            }
            
            let change = transaction.category.direction == .income ? amount : -amount
            dailyTransactions[dayStart, default: 0] += change
        }
        
        var dates: [Date] = []
        var currentDate = thirtyDaysAgo
        while currentDate <= today {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        balanceHistory = dates.map { date in
            let dailyBalance = dailyTransactions[date] ?? 0
            return BalanceData(
                id: UUID(), 
                date: date,
                originalBalance: dailyBalance
            )
        }
    }
}
