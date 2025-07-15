import SwiftUI

struct IncomeHistoryView: View {
    @EnvironmentObject var transactionsViewModel: TransactionsViewModel
    
    var body: some View {
        MyHistoryView()
            .environmentObject(transactionsViewModel)
            .onAppear {
                transactionsViewModel.switchDirection(to: .income)
            }
    }
}

#Preview {
    let currencyService = CurrencyService()
    IncomeHistoryView()
        .environmentObject(currencyService)
}
