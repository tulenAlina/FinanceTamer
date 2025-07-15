import Foundation

final class BankAccountsService {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient = NetworkClient(
        baseURL: "https://shmr-finance.ru/api/v1",
        token: "YQC5f2uw8MWMoiM2H9j96vne"
    )) {
        self.networkClient = networkClient
    }
    
    // Получить все счета пользователя
    func getAllAccounts() async throws -> [BankAccount] {
        try await networkClient.request(
            endpoint: "accounts",
            method: "GET",
            headers: nil,
            body: Optional<String>.none,
            queryParameters: nil
        )
    }
    
    // Получить счет по id
    func getAccount(by id: Int) async throws -> BankAccount {
        try await networkClient.request(
            endpoint: "accounts/\(id)",
            method: "GET",
            headers: nil,
            body: Optional<String>.none,
            queryParameters: nil
        )
    }
    
    // Создать новый счет
    struct AccountCreateRequest: Encodable {
        let name: String
        let balance: String
        let currency: String
    }
    func createAccount(_ request: AccountCreateRequest) async throws -> BankAccount {
        try await networkClient.request(
            endpoint: "accounts",
            method: "POST",
            headers: nil,
            body: request,
            queryParameters: nil
        )
    }
    
    // Обновить счет
    struct AccountUpdateRequest: Encodable {
        let name: String
        let balance: String
        let currency: String
    }
    func updateAccount(id: Int, request: AccountUpdateRequest) async throws -> BankAccount {
        try await networkClient.request(
            endpoint: "accounts/\(id)",
            method: "PUT",
            headers: nil,
            body: request,
            queryParameters: nil
        )
    }
    
    // Удалить счет
    func deleteAccount(id: Int) async throws {
        _ = try await networkClient.request(
            endpoint: "accounts/\(id)",
            method: "DELETE",
            headers: nil,
            body: Optional<String>.none,
            queryParameters: nil
        ) as EmptyResponse
    }
}
