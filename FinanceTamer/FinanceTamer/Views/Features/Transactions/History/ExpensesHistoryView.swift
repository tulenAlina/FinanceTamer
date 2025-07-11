import SwiftUI

struct ExpensesHistoryView: View {
    @EnvironmentObject var transactionsViewModel: TransactionsViewModel
    @StateObject private var viewModel: MyHistoryViewModel
    
    init() {
        let transactionsService = TransactionsService()
        let categoriesService = CategoriesService()
        _viewModel = StateObject(
            wrappedValue: MyHistoryViewModel(
                transactionsService: transactionsService,
                categoriesService: categoriesService,
                selectedDirection: .outcome
            )
        )
    }
    
    var body: some View {
        MyHistoryView(viewModel: viewModel)
            .environmentObject(transactionsViewModel)
            .onAppear {
                transactionsViewModel.switchDirection(to: .outcome)
            }
    }
}

#Preview {
    ExpensesHistoryView()
}
