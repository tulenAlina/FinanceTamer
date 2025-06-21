
import Foundation

enum ParsingError: Error, LocalizedError {
    case invalidJSONStructure
    case missingRequiredField(String)
    case invalidAmountFormat(String)
    case invalidDateFormat(String)
    case invalidDataFormat(String)
    case invalidCSVFormat
    case lineParseError(line: Int, error: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidJSONStructure:
            return "Некорректная структура JSON"
        case .missingRequiredField(let field):
            return "Отсутствует обязательное поле: \(field)"
        case .invalidAmountFormat(let value):
            return "Некорректный формат суммы: \(value)"
        case .invalidDateFormat(let value):
            return "Некорректный формат даты: \(value)"
        case .invalidDataFormat(let message):
            return "Некорректные данные: \(message)"
        case .invalidCSVFormat:
            return "Некорректный формат CSV"
        case .lineParseError(let line, let error):
            return "Ошибка при парсинге строки \(line): \(error.localizedDescription)"
        }
    }
}
