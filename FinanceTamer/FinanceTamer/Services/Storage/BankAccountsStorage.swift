import Foundation

protocol BankAccountsStorage {
    func getAllAccounts() async throws -> [BankAccount]
    func updateAccount(_ account: BankAccount) async throws
    func createAccount(_ account: BankAccount) async throws
    func deleteAccount(id: Int) async throws
}
