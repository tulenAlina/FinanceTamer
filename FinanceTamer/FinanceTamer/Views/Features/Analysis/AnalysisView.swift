import SwiftUI

struct AnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedDirection: Direction
    
    var body: some View {
        AnalysisViewControllerWrapper(selectedDirection: selectedDirection)
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
    
    func makeUIViewController(context: Context) -> AnalysisViewController {
            let vc = createViewController()
            
            let navController = UINavigationController(rootViewController: vc)
            navController.navigationBar.prefersLargeTitles = false
            navController.navigationBar.tintColor = UIColor(named: "navigationColor")

            return vc
        }

    
    func updateUIViewController(_ uiViewController: AnalysisViewController, context: Context) {
        // Просто пересоздаем контроллер при изменении направления
        // UIKit сам позаботится о переходе
    }
    
    private func createViewController() -> AnalysisViewController {
        let transactionsService = TransactionsService()
        let categoriesService = CategoriesService()
        let viewModel = MyHistoryViewModel(
            transactionsService: transactionsService,
            categoriesService: categoriesService,
            selectedDirection: selectedDirection
        )
        return AnalysisViewController(viewModel: viewModel)
    }
}

