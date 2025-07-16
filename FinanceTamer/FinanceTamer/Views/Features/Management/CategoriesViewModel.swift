import SwiftUI

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var error: Error?
    private let categoriesService = CategoriesService()
    
    func isCancelledError(_ error: Error) -> Bool {
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }
        if let networkError = error as? NetworkError {
            switch networkError {
            case .networkError(let err):
                return isCancelledError(err)
            default:
                return false
            }
        }
        return false
    }
    
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
            if isCancelledError(error) || Task.isCancelled {
                return
            }
            print("[ERROR SET] CategoriesViewModel error: \(error)\nCallstack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
            self.error = error
            print("Ошибка загрузки категорий: \(error)")
        }
    }
}
