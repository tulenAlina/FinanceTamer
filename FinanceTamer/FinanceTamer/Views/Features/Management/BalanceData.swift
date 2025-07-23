import Foundation

struct BalanceData: Identifiable {
    let id: UUID
    let date: Date
    let originalBalance: Decimal
    var balance: Decimal { abs(originalBalance) } // Отображаем по модулю
    var isPositive: Bool { originalBalance >= 0 } // Цвет зависит от знака
}
