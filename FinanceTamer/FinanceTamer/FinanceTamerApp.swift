import SwiftUI

@main
struct FinanceTamerApp: App {
    @StateObject private var transactionsVM = TransactionsViewModel(
        transactionsService: TransactionsService(),
        categoriesService: CategoriesService(),
        selectedDirection: .outcome
    )
    
    private let currencyService = CurrencyService.shared
    
    var body: some Scene {
        WindowGroup {
            TabBarView()
                .environmentObject(transactionsVM)
                .environmentObject(currencyService)
        }
    }
}
