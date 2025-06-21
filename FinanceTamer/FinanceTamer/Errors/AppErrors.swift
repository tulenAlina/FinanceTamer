import Foundation

enum AppError: Error, LocalizedError {
    case notFound
    case invalidData
    case networkError
    case unauthorized
    case custom(message: String)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Запрашиваемый ресурс не найден"
        case .invalidData:
            return "Некорректные данные"
        case .networkError:
            return "Ошибка сети"
        case .unauthorized:
            return "Требуется авторизация"
        case .custom(let message):
            return message
        }
    }
}
