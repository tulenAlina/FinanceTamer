import Foundation

/// Сервис для работы с банковскими счетами
final class BankAccountsService {
    private var mockAccounts: [BankAccount] = [
        BankAccount(id: 1, userId: 1, name: "Основной счёт", balance: 10000, currency: "RUB", createdAt: Date(), updatedAt: Date())
    ]
    
    /// Получает основной счет пользователя
    func getPrimaryAccount(for userId: Int) async throws -> BankAccount {
        try await Task.sleep(nanoseconds: 500_000_000) // Имитация задержки
        guard let account = mockAccounts.first(where: { $0.userId == userId }) else {
            throw NSError(domain: "No accounts available", code: 404)
        }
        return account
    }
    
    /// Обновляет данные счета
    func updateAccount(_ account: BankAccount) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // Имитация задержки
        if let index = mockAccounts.firstIndex(where: { $0.id == account.id }) {
            mockAccounts[index] = account
        } else {
            throw NSError(domain: "Account not found", code: 404)
        }
    }
}
