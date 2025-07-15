import SwiftUI

enum SortType: String, CaseIterable, Identifiable {
    case dateAscending = "Дата (сначала старые)"
    case dateDescending = "Дата (сначала новые)"
    case amountAscending = "Сумма (по возрастанию)"
    case amountDescending = "Сумма (по убыванию)"
    
    var id: String { self.rawValue }
    var isDateSorting: Bool {
        return self == .dateAscending || self == .dateDescending
    }
}

@MainActor
final class MyHistoryViewModel: ObservableObject {
    @Published var selectedDirection: Direction = .outcome {
        didSet {
            filterTransactions()
        }
    }
    @Published var totalAmount: Decimal = 0
    @Published var allTransactions: [TransactionResponse] = []
    @Published var displayedTransactions: [TransactionResponse] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var sortType: SortType = .dateAscending
    
    private let transactionsService: TransactionsService
    private let categoriesService: CategoriesService
    
    var sortedTransactions: [TransactionResponse] {
        let isoFormatter = ISO8601DateFormatter()
        switch sortType {
        case .dateAscending:
            return displayedTransactions.sorted {
                let d0 = isoFormatter.date(from: $0.transactionDate) ?? Date.distantPast
                let d1 = isoFormatter.date(from: $1.transactionDate) ?? Date.distantPast
                return d0 < d1
            }
        case .dateDescending:
            return displayedTransactions.sorted {
                let d0 = isoFormatter.date(from: $0.transactionDate) ?? Date.distantPast
                let d1 = isoFormatter.date(from: $1.transactionDate) ?? Date.distantPast
                return d0 > d1
            }
        case .amountAscending:
            return displayedTransactions.sorted { (Decimal(string: $0.amount) ?? 0) < (Decimal(string: $1.amount) ?? 0) }
        case .amountDescending:
            return displayedTransactions.sorted { (Decimal(string: $0.amount) ?? 0) > (Decimal(string: $1.amount) ?? 0) }
        }
    }
    
    init(transactionsService: TransactionsService, categoriesService: CategoriesService,  selectedDirection: Direction) {
        self.transactionsService = transactionsService
        self.categoriesService = categoriesService
        self.selectedDirection = selectedDirection
    }
    
    func loadData(from startDate: Date, to endDate: Date, accountId: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            let start = dateFormatter.string(from: startDate)
            let end = dateFormatter.string(from: endDate)
            async let transactionsTask = transactionsService.getTransactions(accountId: accountId, startDate: start, endDate: end)
            async let categoriesTask = categoriesService.getAllCategories()
            let (transactions, categories) = await (try transactionsTask, try categoriesTask)
            self.allTransactions = transactions
            self.categories = categories
            self.displayedTransactions = transactions
            filterTransactions()
            self.totalAmount = calculateTotalAmount()
        } catch {
            self.error = error
            print("Ошибка загрузки:", error.localizedDescription)
        }
    }
    
    func category(for transaction: TransactionResponse) -> Category? {
        categories.first { $0.id == transaction.category.id }
    }
    
    private func calculateTotalAmount() -> Decimal {
        displayedTransactions.reduce(0) { $0 + (Decimal(string: $1.amount) ?? 0) }
    }
    
    private func filterTransactions() {
        displayedTransactions = allTransactions.filter { transaction in
            guard let category = category(for: transaction) else { return false }
            return category.direction == selectedDirection
        }
    }
}
