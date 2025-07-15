import SwiftUI

struct NewIncomeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currencyService: CurrencyService
    @EnvironmentObject var transactionsViewModel: TransactionsViewModel
    private let transactionsService = TransactionsService()
    private let categoriesService = CategoriesService()
    private let bankAccountsService = BankAccountsService()
    
    var body: some View {
        TransactionEditView(
            mode: .create(.income),
            transactionsService: transactionsService,
            categoriesService: categoriesService,
            bankAccountsService: bankAccountsService,
            transactionsViewModel: transactionsViewModel
        )
        .environmentObject(currencyService)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Назад")
                    }
                    .tint(Color.navigation)
                }
            }
        }
        .onDisappear {
        }
    }
}

#Preview {
    let currencyService = CurrencyService()
    NewIncomeView()
        .environmentObject(currencyService)
}
