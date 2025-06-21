import Foundation

/// Сервис для работы с категориями
final class CategoriesService {
    var mockCategories: [Category] = [
        Category(id: 1, name: "Зарплата", emoji: "💰", direction: .income),
        Category(id: 2, name: "Подарок", emoji: "🎁", direction: .income),
        Category(id: 3, name: "Продукты", emoji: "🛒", direction: .outcome),
        Category(id: 4, name: "Кафе", emoji: "☕️", direction: .outcome),
        Category(id: 5, name: "Транспорт", emoji: "🚕", direction: .outcome),
        Category(id: 6, name: "Жильё", emoji: "🏠", direction: .outcome),
        Category(id: 7, name: "Развлечения", emoji: "🎭", direction: .outcome)
    ]
    
    /// Получает все категории
    func categories() async throws -> [Category] {
        try await Task.sleep(nanoseconds: 500_000_000) // Имитация задержки
        return mockCategories
    }
    
    /// Получает категории по направлению
    func categories(for direction: Direction) async throws -> [Category] {
        try await Task.sleep(nanoseconds: 500_000_000) // Имитация задержки
        return mockCategories.filter { $0.direction == direction }
    }
}
