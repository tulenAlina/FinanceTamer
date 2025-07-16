import Foundation

@MainActor
final class TransactionsService {
    private let networkClient: NetworkClient
    private let localStorage: TransactionsStorage
    private let backupStorage: TransactionsBackupStorage
    
    init(
        networkClient: NetworkClient = NetworkClient(
            baseURL: "https://shmr-finance.ru/api/v1",
            token: "YQC5f2uw8MWMoiM2H9j96vne"
        ),
        localStorage: TransactionsStorage? = nil,
        backupStorage: TransactionsBackupStorage? = nil
    ) {
        self.networkClient = networkClient
        self.localStorage = localStorage ?? SwiftDataTransactionsStorage()
        self.backupStorage = backupStorage ?? SwiftDataTransactionsBackupStorage()
    }
    
    // MARK: - Синхронизация бэкапа
    private func syncBackup() async {
        let backupOps = (try? await backupStorage.getAllBackupOperations()) ?? []
        for op in backupOps {
            do {
                switch op.type {
                case .create:
                    let req = TransactionRequest.fromResponse(op.transaction)
                    _ = try await networkClient.request(
                        endpoint: "transactions",
                        method: "POST",
                        headers: nil,
                        body: req,
                        queryParameters: nil
                    ) as EmptyResponse
                case .update:
                    let req = TransactionRequest.fromResponse(op.transaction)
                    _ = try await networkClient.request(
                        endpoint: "transactions/\(op.transaction.id)",
                        method: "PUT",
                        headers: nil,
                        body: req,
                        queryParameters: nil
                    ) as TransactionResponse
                case .delete:
                    _ = try await networkClient.request(
                        endpoint: "transactions/\(op.transaction.id)",
                        method: "DELETE",
                        headers: nil,
                        body: Optional<String>.none,
                        queryParameters: nil
                    ) as EmptyResponse
                }
                try await backupStorage.removeBackupOperation(id: op.id)
            } catch {
                // Если не удалось — оставляем в бэкапе
            }
        }
    }
    
    // MARK: - Получить транзакцию по ID
    func getTransaction(by id: Int) async throws -> TransactionResponse {
        try await networkClient.request(
            endpoint: "transactions/\(id)",
            method: "GET",
            headers: nil,
            body: Optional<String>.none,
            queryParameters: nil
        )
    }
    
    // MARK: - Создать новую транзакцию
    func createTransaction(_ request: TransactionRequest) async throws {
        do {
            _ = try await networkClient.request(
                endpoint: "transactions",
                method: "POST",
                headers: nil,
                body: request,
                queryParameters: nil
            ) as EmptyResponse
            let response = TransactionResponse.fromRequest(request)
            try await localStorage.createTransaction(response)
            try await backupStorage.removeBackupOperation(id: response.id)
        } catch {
            let response = TransactionResponse.fromRequest(request)
            let op = BackupOperation(id: response.id, type: .create, transaction: response)
            try await backupStorage.addBackupOperation(op)
            throw error
        }
    }
    
    // MARK: - Обновить транзакцию
    func updateTransaction(id: Int, request: TransactionRequest) async throws -> TransactionResponse {
        do {
            let response: TransactionResponse = try await networkClient.request(
                endpoint: "transactions/\(id)",
                method: "PUT",
                headers: nil,
                body: request,
                queryParameters: nil
            )
            try await localStorage.updateTransaction(id: id, with: response)
            try await backupStorage.removeBackupOperation(id: id)
            return response
        } catch {
            let response = TransactionResponse.fromRequest(request, id: id)
            let op = BackupOperation(id: id, type: .update, transaction: response)
            try await backupStorage.addBackupOperation(op)
            throw error
        }
    }
    
    // MARK: - Удалить транзакцию
    func deleteTransaction(id: Int) async throws {
        do {
            _ = try await networkClient.request(
                endpoint: "transactions/\(id)",
                method: "DELETE",
                headers: nil,
                body: Optional<String>.none,
                queryParameters: nil
            ) as EmptyResponse
            try await localStorage.deleteTransaction(id: id)
            try await backupStorage.removeBackupOperation(id: id)
        } catch {
            // Для удаления в бэкапе достаточно id
            let fake = TransactionResponse(
                id: id,
                account: AccountBrief(id: 0, name: "", balance: "0", currency: ""),
                category: Category(id: 0, name: "", emoji: "💸", direction: .outcome),
                amount: "0",
                transactionDate: "",
                comment: nil,
                createdAt: "",
                updatedAt: ""
            )
            let op = BackupOperation(id: id, type: .delete, transaction: fake)
            try await backupStorage.addBackupOperation(op)
            throw error
        }
    }
    
    // MARK: - Получить транзакции по счету за период
    func getTransactions(accountId: Int, startDate: String? = nil, endDate: String? = nil) async throws -> [TransactionResponse] {
        await syncBackup()
        var query: [String: String] = [:]
        if let startDate = startDate { query["startDate"] = startDate }
        if let endDate = endDate { query["endDate"] = endDate }
        do {
            let remote: [TransactionResponse] = try await networkClient.request(
                endpoint: "transactions/account/\(accountId)/period",
                method: "GET",
                headers: nil,
                body: Optional<String>.none,
                queryParameters: query.isEmpty ? nil : query
            )
            // Сохраняем новые операции в локальное хранилище
            for tx in remote {
                try await localStorage.createTransaction(tx)
            }
            return remote
        } catch {
            // Если не удалось — возвращаем объединённый список из локального хранилища и бэкапа
            let local = try await localStorage.getAllTransactions()
            let backup = try await backupStorage.getAllBackupOperations().map { $0.transaction }
            let all = (local + backup)
            // Фильтрация по периоду
            let filtered = all.filter { tx in
                let date = ISO8601DateFormatter().date(from: tx.transactionDate) ?? Date.distantPast
                let start = startDate.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date.distantPast
                let end = endDate.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date.distantFuture
                return date >= start && date <= end
            }
            return filtered
        }
    }
}

// MARK: - Вспомогательные методы для маппинга

extension TransactionRequest {
    static func fromResponse(_ response: TransactionResponse) -> TransactionRequest {
        TransactionRequest(
            accountId: response.account.id,
            categoryId: response.category.id,
            amount: response.amount,
            transactionDate: response.transactionDate,
            comment: response.comment
        )
    }
}

extension TransactionResponse {
    static func fromRequest(_ request: TransactionRequest, id: Int? = nil) -> TransactionResponse {
        TransactionResponse(
            id: id ?? Int(Date().timeIntervalSince1970),
            account: AccountBrief(id: request.accountId, name: "", balance: "0", currency: ""),
            category: Category(id: request.categoryId, name: "", emoji: "💸", direction: .outcome),
            amount: request.amount,
            transactionDate: request.transactionDate,
            comment: request.comment,
            createdAt: request.transactionDate,
            updatedAt: request.transactionDate
        )
    }
}

