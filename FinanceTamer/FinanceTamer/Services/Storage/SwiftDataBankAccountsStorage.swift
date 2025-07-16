import Foundation
import SwiftData

@Model
final class LocalBankAccount: Identifiable {
    @Attribute(.unique) var id: Int
    var name: String
    var balance: String

    init(id: Int, name: String, balance: String) {
        self.id = id
        self.name = name
        self.balance = balance
    }

    func toBankAccount() -> BankAccount {
        BankAccount(
            id: id,
            userId: nil,
            name: name,
            balance: balance,
            currency: "RUB",
            createdAt: "",
            updatedAt: ""
        )
    }

    static func fromBankAccount(_ account: BankAccount) -> LocalBankAccount {
        LocalBankAccount(id: account.id, name: account.name, balance: account.balance)
    }
}

@MainActor
final class SwiftDataBankAccountsStorage: BankAccountsStorage {
    private let container: ModelContainer

    init() {
        self.container = try! ModelContainer(for: LocalBankAccount.self, configurations: ModelConfiguration("accounts"))
    }

    func getAllAccounts() async throws -> [BankAccount] {
        let context = container.mainContext
        let local = try context.fetch(FetchDescriptor<LocalBankAccount>())
        return local.map { $0.toBankAccount() }
    }

    func updateAccount(_ account: BankAccount) async throws {
        let context = container.mainContext
        let fetch = FetchDescriptor<LocalBankAccount>(predicate: #Predicate { $0.id == account.id })
        if let local = try context.fetch(fetch).first {
            local.name = account.name
            local.balance = account.balance
            try context.save()
        }
    }

    func createAccount(_ account: BankAccount) async throws {
        let context = container.mainContext
        let local = LocalBankAccount.fromBankAccount(account)
        context.insert(local)
        try context.save()
    }

    func deleteAccount(id: Int) async throws {
        let context = container.mainContext
        let fetch = FetchDescriptor<LocalBankAccount>(predicate: #Predicate { $0.id == id })
        if let local = try context.fetch(fetch).first {
            context.delete(local)
            try context.save()
        }
    }
}
