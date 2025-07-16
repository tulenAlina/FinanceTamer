import Foundation

final class CategoriesService {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient = NetworkClient(
        baseURL: "https://shmr-finance.ru/api/v1",
        token: "YQC5f2uw8MWMoiM2H9j96vne"
    )) {
        self.networkClient = networkClient
    }
    
    // Получить все категории
    func getAllCategories() async throws -> [Category] {
        try await networkClient.request(
            endpoint: "categories",
            method: "GET",
            headers: nil,
            body: Optional<String>.none,
            queryParameters: nil
        )
    }
    
    // Получить категории по типу (доходы/расходы)
    func getCategories(isIncome: Bool) async throws -> [Category] {
        try await networkClient.request(
            endpoint: "categories/type/\(isIncome)",
            method: "GET",
            headers: nil,
            body: Optional<String>.none,
            queryParameters: nil
        )
    }
}
