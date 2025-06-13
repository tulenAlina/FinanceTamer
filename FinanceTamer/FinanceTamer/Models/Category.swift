/// Модель категории транзакции

struct Category: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let emoji: Character
    let direction: Direction
    
    enum CodingKeys: String, CodingKey {
        case id, name, emoji, isIncome
    }
    
    init(id: Int, name: String, emoji: Character, direction: Direction) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.direction = direction
    }
    
    init(id: Int, name: String, emoji: Character, isIncome: Bool) {
        self.init(
            id: id,
            name: name,
            emoji: emoji,
            direction: isIncome ? .income : .outcome)
        }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        let emojiString = try container.decode(String.self, forKey: .emoji)
        guard let emojiChar = emojiString.first else {
            throw DecodingError.dataCorruptedError(
                forKey: .emoji,
                in: container,
                debugDescription: "emoji string is empty"
            )
        }
        self.emoji = emojiChar
        
        let isIncome = try container.decode(Bool.self, forKey: .isIncome)
        direction = isIncome ? .income : .outcome
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(String(emoji), forKey: .emoji)
        try container.encode(direction == .income, forKey: .isIncome)
    }
}
