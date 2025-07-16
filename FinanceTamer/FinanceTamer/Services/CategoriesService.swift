import Foundation

@MainActor
final class CategoriesService {
    private let networkClient: NetworkClient
    private let localStorage: CategoriesStorage
    
    init(
        networkClient: NetworkClient = NetworkClient(
            baseURL: "https://shmr-finance.ru/api/v1",
            token: "YQC5f2uw8MWMoiM2H9j96vne"
        ),
        localStorage: CategoriesStorage? = nil
    ) {
        self.networkClient = networkClient
        self.localStorage = localStorage ?? SwiftDataCategoriesStorage()
    }
    
    // Получить все категории
    func getAllCategories() async throws -> [Category] {
        do {
            let remote: [Category] = try await networkClient.request(
                endpoint: "categories",
                method: "GET",
                headers: nil,
                body: Optional<String>.none,
                queryParameters: nil
            )
            try await localStorage.saveCategories(remote)
            return remote
        } catch {
            return try await localStorage.getAllCategories()
        }
    }
    
    // Получить категории по типу (доходы/расходы)
    func getCategories(isIncome: Bool) async throws -> [Category] {
        do {
            let remote: [Category] = try await networkClient.request(
                endpoint: "categories/type/\(isIncome)",
                method: "GET",
                headers: nil,
                body: Optional<String>.none,
                queryParameters: nil
            )
            // Можно обновлять только нужные категории, но для простоты обновим все
            let all = try await getAllCategories()
            return remote
        } catch {
            let all = try await localStorage.getAllCategories()
            return all.filter { $0.direction == (isIncome ? .income : .outcome) }
        }
    }
}
