import Foundation

final class TransactionsService {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient = NetworkClient(
        baseURL: "https://shmr-finance.ru/api/v1",
        token: "YQC5f2uw8MWMoiM2H9j96vne"
    )) {
        self.networkClient = networkClient
    }
    
    // Получить транзакцию по ID
    func getTransaction(by id: Int) async throws -> TransactionResponse {
        try await networkClient.request(
            endpoint: "transactions/\(id)",
            method: "GET",
            headers: nil,
            body: Optional<String>.none,
            queryParameters: nil
        )
    }
    
    // Создать новую транзакцию
    func createTransaction(_ request: TransactionRequest) async throws -> TransactionResponse {
        try await networkClient.request(
            endpoint: "transactions",
            method: "POST",
            headers: nil,
            body: request,
            queryParameters: nil
        )
    }
    
    // Обновить транзакцию
    func updateTransaction(id: Int, request: TransactionRequest) async throws -> TransactionResponse {
        try await networkClient.request(
            endpoint: "transactions/\(id)",
            method: "PUT",
            headers: nil,
            body: request,
            queryParameters: nil
        )
    }
    
    // Удалить транзакцию
    func deleteTransaction(id: Int) async throws {
        _ = try await networkClient.request(
            endpoint: "transactions/\(id)",
            method: "DELETE",
            headers: nil,
            body: Optional<String>.none,
            queryParameters: nil
        ) as EmptyResponse
    }
    
    // Получить транзакции по счету за период
    func getTransactions(accountId: Int, startDate: String? = nil, endDate: String? = nil) async throws -> [TransactionResponse] {
        var query: [String: String] = [:]
        if let startDate = startDate { query["startDate"] = startDate }
        if let endDate = endDate { query["endDate"] = endDate }
        return try await networkClient.request(
            endpoint: "transactions/account/\(accountId)/period",
            method: "GET",
            headers: nil,
            body: Optional<String>.none,
            queryParameters: query.isEmpty ? nil : query
        )
    }
}
