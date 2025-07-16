import Foundation

protocol CategoriesStorage {
    func getAllCategories() async throws -> [Category]
    func saveCategories(_ categories: [Category]) async throws
}
