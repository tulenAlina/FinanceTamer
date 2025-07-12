import SwiftUI

struct AnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var transactionsViewModel: TransactionsViewModel
    let selectedDirection: Direction
    
    var body: some View {
        AnalysisViewControllerWrapper(
            selectedDirection: selectedDirection,
            transactionsViewModel: transactionsViewModel
        )
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
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

struct AnalysisViewControllerWrapper: UIViewControllerRepresentable {
    let selectedDirection: Direction
    let transactionsViewModel: TransactionsViewModel
    
    func makeUIViewController(context: Context) -> AnalysisViewController {
        let transactionsService = TransactionsService()
        let categoriesService = CategoriesService()
        let viewModel = MyHistoryViewModel(
            transactionsService: transactionsService,
            categoriesService: categoriesService,
            selectedDirection: selectedDirection
        )
        let analysisVC = AnalysisViewController(viewModel: viewModel)
        
        analysisVC.transactionsViewModel = transactionsViewModel
        
        return analysisVC
    }

    func updateUIViewController(_ uiViewController: AnalysisViewController, context: Context) {
        uiViewController.transactionsViewModel = transactionsViewModel
    }
}

