import SwiftUI
import OSLog

@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var displayedTransactions: [Transaction] = []
    @Published var allTransactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var sortType: SortType = .dateDescending {
        didSet {
            sortTransactions()
        }
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
    }
    
    func loadTransactions() async {
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
            self.error = error
            os_log("Ошибка создания транзакции: %@", log: .default, type: .error, error.localizedDescription)
        }
    }
    
    func deleteTransaction(withId id: Int) async {
        do {
            try await transactionsService.deleteTransaction(withId: id)
            await loadTransactions()
        } catch {
            self.error = error
            os_log("Ошибка удаления транзакции: %@", log: .default, type: .error, error.localizedDescription)
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
}
