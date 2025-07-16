import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case unauthorized
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный URL."
        case .invalidResponse:
            return "Некорректный ответ от сервера."
        case .serverError(let code):
            if code == 401 { return "Неавторизованный доступ." }
            if code == 400 { return "Некорректные данные." }
            if code == 404 { return "Ресурс не найден." }
            if code == 500 { return "Внутренняя ошибка сервера. Попробуйте позже." }
            return "Ошибка сервера. Код: \(code)"
        case .decodingError:
            return "Ошибка обработки данных."
        case .encodingError:
            return "Ошибка подготовки данных."
        case .networkError(let err):
            return err.localizedDescription
        case .unauthorized:
            return "Неавторизованный доступ."
        case .unknown:
            return "Неизвестная ошибка."
        }
    }
}

final class NetworkClient {
    private let baseURL: URL
    private let token: String
    private let urlSession: URLSession

    init(baseURL: String, token: String) {
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid base URL")
        }
        self.baseURL = url
        self.token = token
        self.urlSession = URLSession(configuration: .default)
    }

    func request<Request: Encodable, Response: Decodable>(
        endpoint: String,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: Request? = nil,
        queryParameters: [String: String]? = nil
    ) async throws -> Response {
        var url = baseURL.appendingPathComponent(endpoint)
        if let queryParameters = queryParameters, !queryParameters.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            if let urlWithQuery = components?.url {
                url = urlWithQuery
            }
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        if let body = body {
            do {
                request.httpBody = try await withCheckedThrowingContinuation { cont in
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            let data = try JSONEncoder().encode(body)
                            cont.resume(returning: data)
                        } catch {
                            cont.resume(throwing: NetworkError.encodingError(error))
                        }
                    }
                }
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                print("[NetworkClient] Ошибка кодирования тела запроса для endpoint: \(endpoint):", error)
                throw NetworkError.encodingError(error)
            }
        }
        // Логируем запрос
        print("[NetworkClient] Запрос: \(method) \(url.absoluteString)")
        if let body = body {
            if let data = try? JSONEncoder().encode(body),
               let json = String(data: data, encoding: .utf8) {
                print("[NetworkClient] Тело запроса: \n\(json)")
            }
        }
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[NetworkClient] Некорректный ответ от сервера для endpoint: \(endpoint)")
                throw NetworkError.invalidResponse
            }
            print("[NetworkClient] Статус ответа: \(httpResponse.statusCode) для endpoint: \(endpoint)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("[NetworkClient] Тело ответа: \n\(responseString)")
            }
            if !(200...299).contains(httpResponse.statusCode) {
                if httpResponse.statusCode == 401 {
                    print("[NetworkClient] Неавторизованный доступ для endpoint: \(endpoint)")
                    throw NetworkError.unauthorized
                }
                print("[NetworkClient] Ошибка сервера (\(httpResponse.statusCode)) для endpoint: \(endpoint)")
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
            do {
                return try await withCheckedThrowingContinuation { cont in
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            let decoded = try JSONDecoder().decode(Response.self, from: data)
                            cont.resume(returning: decoded)
                        } catch {
                            print("[NetworkClient] Ошибка декодирования ответа для endpoint: \(endpoint):", error)
                            cont.resume(throwing: NetworkError.decodingError(error))
                        }
                    }
                }
            } catch {
                print("[NetworkClient] Ошибка декодирования (catch) для endpoint: \(endpoint):", error)
                throw NetworkError.decodingError(error)
            }
        } catch {
            print("[NetworkClient] Сетевая ошибка для endpoint: \(endpoint):", error)
            throw NetworkError.networkError(error)
        }
    }
}
