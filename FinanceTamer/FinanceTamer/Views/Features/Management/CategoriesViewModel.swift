import SwiftUI

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var error: Error?
    private let categoriesService = CategoriesService()
    
    func loadCategories(for direction: Direction? = nil) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            if let direction = direction {
                let isIncome = direction == .income
                categories = try await categoriesService.getCategories(isIncome: isIncome)
            } else {
                categories = try await categoriesService.getAllCategories()
            }
        } catch {
            self.error = error
            print("Ошибка загрузки категорий: \(error)")
        }
    }
}
