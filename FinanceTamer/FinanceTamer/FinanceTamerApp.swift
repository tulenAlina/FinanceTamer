import SwiftUI

@main
struct FinanceTamerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    testImplementation()
                }
        }
    }
    
    private func testImplementation() {
        Task {
            do {
                // Тестирование CategoriesService
                let categoriesService = CategoriesService()
                let allCategories = try await categoriesService.categories()
                print("All categories: \(allCategories)")
                
                // Тестирование BankAccountsService
                let bankAccountsService = BankAccountsService()
                let account = try await bankAccountsService.getPrimaryAccount(for: 1)
                print("Primary account: \(account)")
                
                // Тестирование TransactionsService
                let transactionsService = TransactionsService()
                let newTransaction = try await transactionsService.createTransaction(
                    accountId: 0,
                    amount: 1000,
                    transactionDate: Date(),
                    categoryId: 1,
                    comment: "Тестовая транзакция"
                )
                print("Created transaction: \(newTransaction)")
                
                let transactions = try await transactionsService.getTransactions(
                    for: Date().addingTimeInterval(-86400)...Date()
                )
                print("Today's transactions: \(transactions)")
                
            } catch {
                print("Error during testing: \(error)")
            }
        }
    }
}
