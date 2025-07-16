import SwiftUI
import OSLog

@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var displayedTransactions: [TransactionResponse] = []
    @Published var allTransactions: [TransactionResponse] = []
    @Published var categories: [Category] = []
    @Published var isLoading = true
    @Published var error: Error?
    @Published var saveSuccess = false
    @Published var lastUpdateTime = Date()
    @Published private var currency = Currency.rub
    @Published var sortType: SortType = .dateDescending {
        didSet {
            sortTransactions()
        }
    }
    
    private var isDeleting = false
    
    var totalAmount: Decimal {
        displayedTransactions.reduce(0) { $0 + (Decimal(string: $1.amount) ?? 0) }
    }
    
    var selectedDirection: Direction = .outcome {
        didSet {
            filterTransactions()
        }
    }
    
    private let transactionsService: TransactionsService
    private let categoriesService: CategoriesService
    private var loadTask: Task<Void, Never>?
    
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
    
    var totalAmountToday: String {
        let todayInterval = Date.todayInterval()
        let isoFormatter = ISO8601DateFormatter()
        let todayTransactions = displayedTransactions.filter { transaction in
            guard let date = isoFormatter.date(from: transaction.transactionDate) else { return false }
            return date >= todayInterval.lowerBound && date <= todayInterval.upperBound
        }
        let total = todayTransactions.reduce(0) { $0 + (Decimal(string: $1.amount) ?? 0) }
        return NumberFormatter.currency(symbol: "₽").string(from: NSDecimalNumber(decimal: total)) ?? "0 ₽"
    }
    
    init(
        transactionsService: TransactionsService,
        categoriesService: CategoriesService,
        selectedDirection: Direction
    ) {
        self.transactionsService = transactionsService
        self.categoriesService = categoriesService
        self.selectedDirection = selectedDirection
    }
    
    func loadTransactions() async {
        loadTask = Task { [weak self] in
            guard let self = self else { print("self is nil"); return }
            defer {
                self.isLoading = false
                print("Конец загрузки транзакций, isLoading = \(self.isLoading)")
            }
            print("loadTransactions: isLoading перед установкой = \(self.isLoading)")
            // Устанавливаем isLoading только если он еще не установлен
            if !self.isLoading {
                self.isLoading = true
            }
            print("Начало загрузки транзакций")
            do {
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
                let accounts = try? await BankAccountsService().getAllAccounts()
                try Task.checkCancellation()
                let accountId = accounts?.first?.id ?? 1
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withFullDate]
                let start = dateFormatter.string(from: startDate)
                let end = dateFormatter.string(from: endDate)
                let transactions = try await self.transactionsService.getTransactions(accountId: accountId, startDate: start, endDate: end)
                try Task.checkCancellation()
                print("Загружено транзакций: \(transactions.count)")
                let categories = try await self.categoriesService.getAllCategories()
                try Task.checkCancellation()
                print("Загружено категорий: \(categories.count)")
                await MainActor.run {
                    self.allTransactions = transactions
                    self.categories = categories
                    self.filterTransactions()
                    self.lastUpdateTime = Date()
                }
            } catch {
                print("Catch в loadTransactions, Task.isCancelled = \(Task.isCancelled)")
                if self.isCancelledError(error) || Task.isCancelled {
                    print("Загрузка отменена")
                    return
                }
                print("Ошибка загрузки: \(error)")
                await MainActor.run {
                    print("[ERROR SET] TransactionsViewModel error: \(error)\nCallstack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
                    self.error = error
                }
            }
        }
    }
    
    func category(for transaction: TransactionResponse) -> Category? {
        return categories.first { $0.id == transaction.category.id }
    }
    
    func createTransaction(
        accountId: Int,
        amount: Decimal,
        transactionDate: Date,
        categoryId: Int,
        comment: String? = nil
    ) async {
        let formatter = ISO8601DateFormatter()
        let request = TransactionRequest(
            accountId: accountId,
            categoryId: categoryId,
            amount: amount.description,
            transactionDate: formatter.string(from: transactionDate),
            comment: comment
        )
        do {
            try await transactionsService.createTransaction(request)
            await loadTransactions()
        } catch {
            self.error = error
        }
    }
    
    func deleteTransaction(withId id: Int) async {
        if isDeleting { print("[Удаление] Повторный вызов проигнорирован"); return }
        isDeleting = true
        defer { isDeleting = false }
        let transactionToDelete = allTransactions.first { $0.id == id }
        allTransactions.removeAll { $0.id == id }
        filterTransactions()
        do {
            try await transactionsService.deleteTransaction(id: id)
            await loadTransactions()
        } catch {
            if let networkError = error as? NetworkError {
                switch networkError {
                case .serverError(let code) where code == 404:
                    print("[Удаление] 404 Not Found: \(error) | Тип: \(type(of: error))")
                    await loadTransactions()
                    return // Не кладём ошибку в self.error
                case .decodingError:
                    print("[Удаление] DecodingError: \(error) | Тип: \(type(of: error))")
                    await loadTransactions()
                    return // Не кладём ошибку в self.error
                default:
                    break
                }
            }
            print("Ошибка удаления транзакции: \(error)")
            await MainActor.run {
                print("[ALERT DEBUG] error type: \(type(of: error)), error: \(error)")
                self.error = error
            }
        }
    }
    
    private func sortTransactions() {
        let isoFormatter = ISO8601DateFormatter()
        switch sortType {
        case .dateAscending:
            displayedTransactions.sort {
                let d0 = isoFormatter.date(from: $0.transactionDate) ?? Date.distantPast
                let d1 = isoFormatter.date(from: $1.transactionDate) ?? Date.distantPast
                return d0 < d1
            }
        case .dateDescending:
            displayedTransactions.sort {
                let d0 = isoFormatter.date(from: $0.transactionDate) ?? Date.distantPast
                let d1 = isoFormatter.date(from: $1.transactionDate) ?? Date.distantPast
                return d0 > d1
            }
        case .amountAscending:
            displayedTransactions.sort { (Decimal(string: $0.amount) ?? 0) < (Decimal(string: $1.amount) ?? 0) }
        case .amountDescending:
            displayedTransactions.sort { (Decimal(string: $0.amount) ?? 0) > (Decimal(string: $1.amount) ?? 0) }
        }
    }
    
    private func filterTransactions() {
        displayedTransactions = allTransactions.filter { transaction in
            guard let category = category(for: transaction) else { return false }
            return category.direction == selectedDirection
        }
        sortTransactions()
    }
    
    func updateTransaction(_ transaction: TransactionResponse) async {
        await loadTransactions()
    }
    
    func switchDirection(to direction: Direction) {
        selectedDirection = direction
        // Отменяем только при смене фильтра/экрана
        loadTask?.cancel()
        // Показываем индикатор загрузки при смене направления
        isLoading = true
        // Очищаем отображаемые транзакции для мгновенной обратной связи
        displayedTransactions = []
        Task {
            await loadTransactions()
        }
    }
}
