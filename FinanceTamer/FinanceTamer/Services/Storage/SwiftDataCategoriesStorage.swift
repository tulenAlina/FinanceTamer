import Foundation
import SwiftData

@Model
final class LocalCategory: Identifiable {
    @Attribute(.unique) var id: Int
    var name: String
    var emoji: String
    var directionRaw: String
    
    init(id: Int, name: String, emoji: String, directionRaw: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.directionRaw = directionRaw
    }
    
    func toCategory() -> Category {
        Category(id: id, name: name, emoji: emoji.first ?? " ", direction: Direction(rawValue: directionRaw) ?? .outcome)
    }
    
    static func fromCategory(_ category: Category) -> LocalCategory {
        LocalCategory(id: category.id, name: category.name, emoji: String(category.emoji), directionRaw: category.direction.rawValue)
    }
}

@MainActor
final class SwiftDataCategoriesStorage: CategoriesStorage {
    private let container: ModelContainer
    
    init() {
        self.container = try! ModelContainer(for: LocalCategory.self, configurations: ModelConfiguration("categories"))
    }
    
    func getAllCategories() async throws -> [Category] {
        let context = container.mainContext
        let local = try context.fetch(FetchDescriptor<LocalCategory>())
        return local.map { $0.toCategory() }
    }
    
    func saveCategories(_ categories: [Category]) async throws {
        let context = container.mainContext
        // Удаляем старые
        let all = try context.fetch(FetchDescriptor<LocalCategory>())
        for cat in all { context.delete(cat) }
        // Сохраняем новые
        for category in categories {
            let local = LocalCategory.fromCategory(category)
            context.insert(local)
        }
        try context.save()
    }
}
