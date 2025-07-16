import Foundation

@MainActor
final class BankAccountsService {
    private let networkClient: NetworkClient
    private let localStorage: BankAccountsStorage
    private let backupStorage: BankAccountsBackupStorage
    
    init(
        networkClient: NetworkClient = NetworkClient(
            baseURL: "https://shmr-finance.ru/api/v1",
            token: "YQC5f2uw8MWMoiM2H9j96vne"
        ),
        localStorage: BankAccountsStorage? = nil,
        backupStorage: BankAccountsBackupStorage? = nil
    ) {
        self.networkClient = networkClient
        self.localStorage = localStorage ?? SwiftDataBankAccountsStorage()
        self.backupStorage = backupStorage ?? SwiftDataBankAccountsBackupStorage()
    }
    
    // MARK: - Синхронизация бэкапа
    private func syncBackup() async {
        let backupOps = (try? await backupStorage.getAllBackupOperations()) ?? []
        for op in backupOps {
            do {
                switch op.type {
                case .create:
                    let req = AccountCreateRequest.fromAccount(op.account)
                    _ = try await networkClient.request(
                        endpoint: "accounts",
                        method: "POST",
                        headers: nil,
                        body: req,
                        queryParameters: nil
                    ) as BankAccount
                case .update:
                    let req = AccountUpdateRequest.fromAccount(op.account)
                    _ = try await networkClient.request(
                        endpoint: "accounts/\(op.account.id)",
                        method: "PUT",
                        headers: nil,
                        body: req,
                        queryParameters: nil
                    ) as BankAccount
                case .delete:
                    _ = try await networkClient.request(
                        endpoint: "accounts/\(op.account.id)",
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
    
    // MARK: - Получить все счета пользователя
    func getAllAccounts() async throws -> [BankAccount] {
        await syncBackup()
        do {
            let remote: [BankAccount] = try await networkClient.request(
                endpoint: "accounts",
                method: "GET",
                headers: nil,
                body: Optional<String>.none,
                queryParameters: nil
            )
            for acc in remote {
                try await localStorage.createAccount(acc)
            }
            return remote
        } catch {
            let local = try await localStorage.getAllAccounts()
            let backup = try await backupStorage.getAllBackupOperations().map { $0.account }
            let all = (local + backup)
            // Уникальные по id
            let unique = Dictionary(grouping: all, by: { $0.id }).compactMap { $0.value.first }
            return unique
        }
    }
    
    // MARK: - Получить счет по id
    func getAccount(by id: Int) async throws -> BankAccount {
        try await networkClient.request(
            endpoint: "accounts/\(id)",
            method: "GET",
            headers: nil,
            body: Optional<String>.none,
            queryParameters: nil
        )
    }
    
    // MARK: - Создать новый счет
    struct AccountCreateRequest: Encodable {
        let name: String
        let balance: String
        let currency: String
        static func fromAccount(_ account: BankAccount) -> AccountCreateRequest {
            AccountCreateRequest(name: account.name, balance: account.balance, currency: "RUB")
        }
    }
    func createAccount(_ request: AccountCreateRequest) async throws -> BankAccount {
        do {
            let account: BankAccount = try await networkClient.request(
                endpoint: "accounts",
                method: "POST",
                headers: nil,
                body: request,
                queryParameters: nil
            )
            try await localStorage.createAccount(account)
            try await backupStorage.removeBackupOperation(id: account.id)
            return account
        } catch {
            let fake = BankAccount(
                id: Int(Date().timeIntervalSince1970),
                userId: nil,
                name: request.name,
                balance: request.balance,
                currency: request.currency,
                createdAt: "",
                updatedAt: ""
            )
            let op = AccountBackupOperation(id: fake.id, type: .create, account: fake)
            try await backupStorage.addBackupOperation(op)
            throw error
        }
    }
    
    // MARK: - Обновить счет
    struct AccountUpdateRequest: Encodable {
        let name: String
        let balance: String
        let currency: String
        static func fromAccount(_ account: BankAccount) -> AccountUpdateRequest {
            AccountUpdateRequest(name: account.name, balance: account.balance, currency: "RUB")
        }
    }
    func updateAccount(id: Int, request: AccountUpdateRequest) async throws -> BankAccount {
        do {
            let account: BankAccount = try await networkClient.request(
                endpoint: "accounts/\(id)",
                method: "PUT",
                headers: nil,
                body: request,
                queryParameters: nil
            )
            try await localStorage.updateAccount(account)
            try await backupStorage.removeBackupOperation(id: id)
            return account
        } catch {
            let fake = BankAccount(
                id: id,
                userId: nil,
                name: request.name,
                balance: request.balance,
                currency: request.currency,
                createdAt: "",
                updatedAt: ""
            )
            let op = AccountBackupOperation(id: id, type: .update, account: fake)
            try await backupStorage.addBackupOperation(op)
            throw error
        }
    }
    
    // MARK: - Удалить счет
    func deleteAccount(id: Int) async throws {
        do {
            _ = try await networkClient.request(
                endpoint: "accounts/\(id)",
                method: "DELETE",
                headers: nil,
                body: Optional<String>.none,
                queryParameters: nil
            ) as EmptyResponse
            try await localStorage.deleteAccount(id: id)
            try await backupStorage.removeBackupOperation(id: id)
        } catch {
            let fake = BankAccount(
                id: id,
                userId: nil,
                name: "",
                balance: "0",
                currency: "RUB",
                createdAt: "",
                updatedAt: ""
            )
            let op = AccountBackupOperation(id: id, type: .delete, account: fake)
            try await backupStorage.addBackupOperation(op)
            throw error
        }
    }
}
