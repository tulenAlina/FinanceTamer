import Foundation
import SwiftData

@Model
final class LocalTransaction: Identifiable {
    @Attribute(.unique) var id: Int
    var amount: String
    var categoryId: Int
    var transactionDate: String
    var comment: String?
    // Добавьте другие необходимые поля
    
    init(id: Int, amount: String, categoryId: Int, transactionDate: String, comment: String?) {
        self.id = id
        self.amount = amount
        self.categoryId = categoryId
        self.transactionDate = transactionDate
        self.comment = comment
    }
    
    func toResponse() -> TransactionResponse {
        TransactionResponse(
            id: id,
            account: AccountBrief(id: 0, name: "", balance: "0", currency: ""), // TODO: заменить на реальные значения, если появятся
            category: Category(id: categoryId, name: "", emoji: "💸", direction: .outcome), // TODO: заменить на реальные значения, если появятся
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: transactionDate, // TODO: заменить на реальные значения, если появятся
            updatedAt: transactionDate  // TODO: заменить на реальные значения, если появятся
        )
    }
    
    static func fromResponse(_ response: TransactionResponse) -> LocalTransaction {
        LocalTransaction(id: response.id, amount: response.amount, categoryId: response.category.id, transactionDate: response.transactionDate, comment: response.comment)
    }
}

@MainActor
final class SwiftDataTransactionsStorage: TransactionsStorage {
    private let container: ModelContainer
    
    init() {
        self.container = try! ModelContainer(for: LocalTransaction.self, configurations: ModelConfiguration("transactions"))
    }
    
    func getAllTransactions() async throws -> [TransactionResponse] {
        let context = container.mainContext
        let local = try context.fetch(FetchDescriptor<LocalTransaction>())
        return local.map { $0.toResponse() }
    }
    
    func createTransaction(_ transaction: TransactionResponse) async throws {
        let context = container.mainContext
        let local = LocalTransaction.fromResponse(transaction)
        context.insert(local)
        try context.save()
    }
    
    func updateTransaction(id: Int, with transaction: TransactionResponse) async throws {
        let context = container.mainContext
        let fetch = FetchDescriptor<LocalTransaction>(predicate: #Predicate { $0.id == id })
        if let local = try context.fetch(fetch).first {
            local.amount = transaction.amount
            local.categoryId = transaction.category.id
            local.transactionDate = transaction.transactionDate
            local.comment = transaction.comment
            try context.save()
        }
    }
    
    func deleteTransaction(id: Int) async throws {
        let context = container.mainContext
        let fetch = FetchDescriptor<LocalTransaction>(predicate: #Predicate { $0.id == id })
        if let local = try context.fetch(fetch).first {
            context.delete(local)
            try context.save()
        }
    }
}
