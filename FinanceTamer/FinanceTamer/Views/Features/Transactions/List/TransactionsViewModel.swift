import SwiftUI
import OSLog

@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var displayedTransactions: [Transaction] = []
    @Published var allTransactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var saveSuccess = false
    @Published var lastUpdateTime = Date()
    @Published private var currency = CurrencyService.shared.currentCurrency
    @Published var sortType: SortType = .dateDescending {
        didSet {
            sortTransactions()
        }
    }
    
    var totalAmount: Decimal {
        displayedTransactions.reduce(0) { $0 + $1.amount }
    }
    
    var selectedDirection: Direction = .outcome {
        didSet {
            filterTransactions()
        }
    }
    
    private let transactionsService: TransactionsService
    private let categoriesService: CategoriesService
    
    var totalAmountToday: String {
        let todayInterval = Date.todayInterval()
        let todayTransactions = displayedTransactions.filter { transaction in
            transaction.transactionDate >= todayInterval.lowerBound &&
            transaction.transactionDate <= todayInterval.upperBound
        }
        let total = todayTransactions.reduce(0) { $0 + $1.amount }
        return NumberFormatter.currency.string(from: NSDecimalNumber(decimal: total)) ?? "0 ₽"
    }
    
    init(
        transactionsService: TransactionsService,
        categoriesService: CategoriesService,
        selectedDirection: Direction
    ) {
        self.transactionsService = transactionsService
        self.categoriesService = categoriesService
        self.selectedDirection = selectedDirection
        CurrencyService.shared.$currentCurrency
            .assign(to: &$currency)
    }
    
    func loadTransactions() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
            let transactions = try await transactionsService.getTransactions(for: startDate...endDate)
            print("Загружено транзакций: \(transactions.count)")
            
            let categories = try await categoriesService.categories()
            print("Загружено категорий: \(categories.count)")
            
            self.allTransactions = transactions
            self.categories = categories
            filterTransactions()
            self.lastUpdateTime = Date()
        } catch {
            print("Ошибка загрузки: \(error)")
            self.error = error
        }
    }
    
    func category(for transaction: Transaction) -> Category? {
        return categories.first { $0.id == transaction.categoryId }
    }
    
    func createTransaction(
        accountId: Int,
        amount: Decimal,
        transactionDate: Date,
        categoryId: Int,
        comment: String? = nil
    ) async {
        let newTransaction = Transaction(
            id: 0, 
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        allTransactions.append(newTransaction)
        filterTransactions()
        
        do {
            try await transactionsService.createTransaction(
                accountId: accountId,
                amount: amount,
                transactionDate: transactionDate,
                categoryId: categoryId,
                comment: comment
            )
            await loadTransactions()
        } catch {
            allTransactions.removeAll { $0.id == newTransaction.id }
            filterTransactions()
            self.error = error
        }
    }
    
    func deleteTransaction(withId id: Int) async {
        let transactionToDelete = allTransactions.first { $0.id == id }
        allTransactions.removeAll { $0.id == id }
        filterTransactions()
        
        do {
            try await transactionsService.deleteTransaction(withId: id)
            await loadTransactions()
        } catch {
            if let transaction = transactionToDelete {
                allTransactions.append(transaction)
                filterTransactions()
            }
            self.error = error
        }
    }
    
    private func sortTransactions() {
        switch sortType {
        case .dateAscending:
            displayedTransactions.sort { $0.transactionDate < $1.transactionDate }
        case .dateDescending:
            displayedTransactions.sort { $0.transactionDate > $1.transactionDate }
        case .amountAscending:
            displayedTransactions.sort { abs($0.amount) < abs($1.amount) }
        case .amountDescending:
            displayedTransactions.sort { abs($0.amount) > abs($1.amount) }
        }
    }
    
    private func filterTransactions() {
        displayedTransactions = allTransactions.filter { transaction in
            guard let category = category(for: transaction) else {return false }
            return category.direction == selectedDirection
        }
        sortTransactions()
    }
    
    func updateTransaction(_ transaction: Transaction) async {
        if let index = displayedTransactions.firstIndex(where: { $0.id == transaction.id }) {
            displayedTransactions[index] = transaction
        }
        do {
            try await transactionsService.updateTransaction(transaction)
            saveSuccess.toggle()
            await loadTransactions()
        } catch {
            await loadTransactions()
            self.error = error
            os_log("Ошибка обновления транзакции: %@", log: .default, type: .error, error.localizedDescription)
        }
    }
    
    func switchDirection(to direction: Direction) {
        selectedDirection = direction
        Task {
            await loadTransactions()
        }
    }
}
