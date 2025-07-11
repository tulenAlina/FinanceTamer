import SwiftUI

@MainActor
class TransactionEditViewModel: ObservableObject {
    enum Mode {
        case create(Direction)
        case edit(Transaction)
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
            return transaction.amount > 0 ? .income : .outcome
        }
        if case let .create(direction) = mode {
            return direction
        }
        return .outcome
    }
    
    private weak var transactionsViewModel: TransactionsViewModel?
    
    init(
        mode: Mode,
        transactionsService: TransactionsService,
        categoriesService: CategoriesService,
        bankAccountsService: BankAccountsService,
        transactionsViewModel: TransactionsViewModel
    )
    {
        self.mode = mode
        self.transactionsService = transactionsService
        self.categoriesService = categoriesService
        self.bankAccountsService = bankAccountsService
        self.transactionsViewModel = transactionsViewModel
        
        if case let .edit(transaction) = mode {
            self.date = transaction.transactionDate
            self.time = transaction.transactionDate
            self.comment = transaction.comment ?? ""
        }
    }
    
    func loadData() {
        Task {
            do {
                availableCategories = try await categoriesService.categories(for: transactionDirection)
                
                if case let .edit(transaction) = mode {
                    selectedCategory = availableCategories.first { $0.id == transaction.categoryId }
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.minimumFractionDigits = 2
                    formatter.maximumFractionDigits = 2
                    amountText = formatter.string(from: NSDecimalNumber(decimal: abs(transaction.amount))) ?? ""
                }
            } catch {
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
        
        guard let transactionDate = calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: calendar.date(from: dateComponents) ?? date
        ) else { return }
        
        do {
            switch mode {
            case .create:
                let account = try await bankAccountsService.getPrimaryAccount(for: 1)
                
                // Обновляем локальное состояние
                await transactionsViewModel?.createTransaction(
                    accountId: account.id,
                    amount: finalAmount,
                    transactionDate: transactionDate,
                    categoryId: category.id,
                    comment: comment
                )
                
            case .edit(let transaction):
                let updatedTransaction = Transaction(
                    id: transaction.id,
                    accountId: transaction.accountId,
                    categoryId: category.id,
                    amount: finalAmount,
                    transactionDate: transactionDate,
                    comment: comment.isEmpty ? nil : comment,
                    createdAt: transaction.createdAt,
                    updatedAt: Date()
                )
                try await transactionsService.updateTransaction(updatedTransaction)
                await transactionsViewModel?.updateTransaction(updatedTransaction)
            }
        } catch {
            print("Error saving transaction: \(error)")
        }
        saveSuccess.toggle()
        if saveSuccess {
                onSave?()
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
        
        // 1. Сначала удаляем локально
        await transactionsViewModel?.deleteTransaction(withId: transaction.id)
        
        // 2. Затем пытаемся удалить на сервере
        do {
            try await transactionsService.deleteTransaction(withId: transaction.id)
            
            // 3. Фоновая синхронизация для актуальности данных
            Task {
                await transactionsViewModel?.loadTransactions()
            }
        } catch {
            print("Error deleting transaction: \(error)")
            
            // 4. Если ошибка - восстанавливаем транзакцию
            await transactionsViewModel?.createTransaction(
                accountId: transaction.accountId,
                amount: transaction.amount,
                transactionDate: transaction.transactionDate,
                categoryId: transaction.categoryId,
                comment: transaction.comment
            )
            
            // Показываем ошибку пользователю
            DispatchQueue.main.async {
                // Здесь можно установить флаг ошибки для отображения пользователю
                print("Не удалось удалить транзакцию: \(error.localizedDescription)")
            }
        }
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
