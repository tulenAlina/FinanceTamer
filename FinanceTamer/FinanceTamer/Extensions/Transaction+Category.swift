import Foundation

extension Transaction {
    var category: Category {
        // Временное решение - позже заменим на получение из сервиса
        CategoriesService().mockCategories.first(where: { $0.id == categoryId })!
    }
}
