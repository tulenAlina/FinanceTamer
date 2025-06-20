// Models/Direction.swift

/// Направление денежного потока (доход/расход)
enum Direction: String, Codable {
    case income  // Доход
    case outcome // Расход
}
