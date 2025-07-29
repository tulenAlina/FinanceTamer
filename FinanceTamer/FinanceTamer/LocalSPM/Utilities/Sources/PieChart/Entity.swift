// LocalSPM/Utilities/Sources/PieChart/Entity.swift
import Foundation

public struct Entity: Equatable {
    public let value: Decimal
    public let label: String
    
    public init(value: Decimal, label: String) {
        self.value = value
        self.label = label
    }
    
    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.value == rhs.value && lhs.label == rhs.label
    }
}
