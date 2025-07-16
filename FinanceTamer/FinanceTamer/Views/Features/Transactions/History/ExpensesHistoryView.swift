import SwiftUI

struct ExpensesHistoryView: View {
    @EnvironmentObject var transactionsViewModel: TransactionsViewModel
    
    var body: some View {
        MyHistoryView()
            .environmentObject(transactionsViewModel)
            .onAppear {
                transactionsViewModel.switchDirection(to: .outcome)
            }
    }
}

#Preview {
    let currencyService = CurrencyService()
    ExpensesHistoryView()
        .environmentObject(currencyService)
}
