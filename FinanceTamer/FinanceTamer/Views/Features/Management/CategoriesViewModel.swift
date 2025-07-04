import SwiftUI

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var categories: [Category] = []
    private let categoriesService = CategoriesService()
    
    func loadCategories(for direction: Direction? = nil) async {
        do {
            if let direction = direction {
                categories = try await categoriesService.categories(for: direction)
            } else {
                categories = try await categoriesService.categories()
            }
        } catch {
            print("Ошибка загрузки категорий: \(error)")
        }
    }
}
