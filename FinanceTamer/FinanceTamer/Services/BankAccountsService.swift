import Foundation

/// Сервис для работы с банковскими счетами
final class BankAccountsService {
    static let shared = BankAccountsService()
    
    private var mockAccounts: [BankAccount] = [
        BankAccount(
            id: 1,
            userId: 1,
            name: "Основной счёт",
            balance: 10000,
            currency: .rub,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    
    private init() {} // Приватный инициализатор для синглтона
    
    /// Получает основной счет пользователя
    func getPrimaryAccount(for userId: Int) async throws -> BankAccount {
        try await Task.sleep(nanoseconds: 500_000_000)
        guard let account = mockAccounts.first(where: { $0.userId == userId }) else {
            throw AppError.notFound
        }
        return account
    }
    
    /// Обновляет данные счета
    func updateAccount(_ account: BankAccount) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        if let index = mockAccounts.firstIndex(where: { $0.id == account.id }) {
            mockAccounts[index] = account
        } else {
            throw AppError.notFound
        }
    }
}
