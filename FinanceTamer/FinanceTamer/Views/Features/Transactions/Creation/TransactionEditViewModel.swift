import SwiftUI

@MainActor
class TransactionEditViewModel: ObservableObject {
    enum Mode {
        case create(Direction)
        case edit(TransactionResponse)
    }
    
    let mode: Mode
    let transactionsService: TransactionsService
    let categoriesService: CategoriesService
    let bankAccountsService: BankAccountsService
    
    @Published var availableCategories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var amountText = ""
    @Published var date = Date()
    @Published var time = Date()
    @Published var comment = ""
    @Published var saveSuccess = false
    @Published var showValidationAlert = false
    @Published var validationMessage = ""
    @Published var isLoading = false
    @Published var error: Error?
    
    var onSave: (() -> Void)?
    
    var navigationTitle: String {
        switch transactionDirection {
        case .income: return "Мои доходы"
        case .outcome: return "Мои расходы"
        }
    }
    
    var saveButtonTitle: String {
        switch mode {
        case .create: return "Создать"
        case .edit: return "Сохранить"
        }
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var currentDate: Date {
        return Date()
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    var isFormValid: Bool {
        selectedCategory != nil && !amountText.isEmpty && Decimal(string: amountText) != nil
    }
    
    var transactionDirection: Direction {
        if case let .edit(transaction) = mode {
            return transaction.category.direction
        }
        if case let .create(direction) = mode {
            return direction
        }
        return .outcome
    }
    
    private weak var transactionsViewModel: TransactionsViewModel?
    
    init(
        mode: Mode,
        transactionsService: TransactionsService = TransactionsService(),
        categoriesService: CategoriesService = CategoriesService(),
        bankAccountsService: BankAccountsService = BankAccountsService(),
        transactionsViewModel: TransactionsViewModel
    )
    {
        self.mode = mode
        self.transactionsService = transactionsService
        self.categoriesService = categoriesService
        self.bankAccountsService = bankAccountsService
        self.transactionsViewModel = transactionsViewModel
        
        if case let .edit(transaction) = mode {
            if let date = ISO8601DateFormatter().date(from: transaction.transactionDate) {
                let now = Date()
                if date > now {
                    self.date = now
                    self.time = now
                } else {
                    self.date = date
                    self.time = date
                }
            }
            self.comment = transaction.comment ?? ""
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
    
    func loadData() {
        isLoading = true
        error = nil
        Task {
            defer { isLoading = false }
            do {
                let isIncome = transactionDirection == .income
                availableCategories = try await categoriesService.getCategories(isIncome: isIncome)
                if case let .edit(transaction) = mode {
                    selectedCategory = availableCategories.first { $0.id == transaction.category.id }
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.minimumFractionDigits = 2
                    formatter.maximumFractionDigits = 2
                    let amountDecimal = abs(Decimal(string: transaction.amount) ?? 0)
                    amountText = formatter.string(from: NSDecimalNumber(decimal: amountDecimal)) ?? ""
                    // Сброс даты, если она в будущем
                    let now = Date()
                    if date > now {
                        date = now
                        time = now
                    }
                }
            } catch {
                if isCancelledError(error) || Task.isCancelled {
                    return
                }
                self.error = error
                print("Error loading data: \(error)")
            }
        }
    }
    
    func save() async {
        guard validateFields() else { return }
        guard let category = selectedCategory,
              let amount = Decimal(string: amountText)?.rounded(2) else { return }
        let finalAmount = category.direction == .outcome ? -amount : amount
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        guard var transactionDate = calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: calendar.date(from: dateComponents) ?? date
        ) else { return }
        // Жёсткая проверка: если дата в будущем, сбрасываем и self.date/self.time на сейчас
        let now = Date()
        if transactionDate > now {
            transactionDate = now
            self.date = now
            self.time = now
        }
        isLoading = true
        error = nil
        var didSave = false
        defer {
            isLoading = false
            if didSave { saveSuccess.toggle(); onSave?() }
        }
        do {
            switch mode {
            case .create:
                let accounts = try await bankAccountsService.getAllAccounts()
                guard let account = accounts.first else {
                    throw NSError(domain: "Нет доступных счетов", code: 0)
                }
                let formattedAmount = String(format: "%.2f", abs(NSDecimalNumber(decimal: finalAmount).doubleValue))
                let request = TransactionRequest(
                    accountId: account.id,
                    categoryId: category.id,
                    amount: formattedAmount,
                    transactionDate: ISO8601DateFormatter().string(from: transactionDate),
                    comment: comment // всегда строка
                )
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                if let data = try? encoder.encode(request), let json = String(data: data, encoding: .utf8) {
                    print("JSON для создания транзакции:\n", json)
                }
                print("Создаём транзакцию:", request)
                try await transactionsService.createTransaction(request)
                await transactionsViewModel?.loadTransactions()
                didSave = true
            case .edit(let transaction):
                let formattedAmount = String(format: "%.2f", abs(NSDecimalNumber(decimal: finalAmount).doubleValue))
                let request = TransactionRequest(
                    accountId: transaction.account.id,
                    categoryId: category.id,
                    amount: formattedAmount,
                    transactionDate: ISO8601DateFormatter().string(from: transactionDate),
                    comment: comment // всегда строка
                )
                print("Обновляем транзакцию:", request)
                try await transactionsService.updateTransaction(id: transaction.id, request: request)
                await transactionsViewModel?.updateTransaction(transaction)
                didSave = true
            }
        } catch {
            if isCancelledError(error) || Task.isCancelled {
                return
            }
            print("[ERROR SET] TransactionEditViewModel error: \(error)\nCallstack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
            self.error = error
            print("Error saving transaction: \(error)")
        }
    }
    
    private func validateFields() -> Bool {
        if selectedCategory == nil {
            validationMessage = "Пожалуйста, выберите категорию"
            showValidationAlert = true
            return false
        }
        
        if amountText.isEmpty {
            validationMessage = "Пожалуйста, укажите сумму"
            showValidationAlert = true
            return false
        }
        
        if Decimal(string: amountText) == nil {
            validationMessage = "Пожалуйста, введите корректную сумму"
            showValidationAlert = true
            return false
        }
        
        return true
    }
    
    func delete() async {
        guard case let .edit(transaction) = mode else { return }
        
        isLoading = true
        error = nil
        await transactionsViewModel?.deleteTransaction(withId: transaction.id)
        // Удалён повторный вызов через transactionsService.deleteTransaction(id:)
        isLoading = false
    }
    
    var maxAllowedTime: Date {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: Date()) {
            return Date()
        } else {
            return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? Date.distantFuture
        }
    }
}

extension Decimal {
    func rounded(_ scale: Int, _ roundingMode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var result = Decimal()
        var localCopy = self
        NSDecimalRound(&result, &localCopy, scale, roundingMode)
        return result
    }
}
