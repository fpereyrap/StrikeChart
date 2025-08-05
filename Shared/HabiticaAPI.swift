import Foundation

@MainActor
class HabiticaAPI: ObservableObject {
    static let shared = HabiticaAPI()
    
    private let baseURL = "https://habitica.com/api/v3"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Authentication
    
    func authenticate(userId: String, apiToken: String) async throws -> HabiticaUser {
        let url = URL(string: "\(baseURL)/user")!
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(userId, forHTTPHeaderField: "x-api-user")
        request.addValue(apiToken, forHTTPHeaderField: "x-api-key")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HabiticaAPIError.authenticationFailed
        }
        
        let apiResponse = try JSONDecoder().decode(HabiticaResponse<HabiticaUser>.self, from: data)
        guard apiResponse.success else {
            throw HabiticaAPIError.apiError(apiResponse.message ?? "Unknown error")
        }
        
        return apiResponse.data
    }
    
    func login(username: String, password: String) async throws -> HabiticaLoginResponse {
        let url = URL(string: "\(baseURL)/user/auth/local/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("StrikeChart-iOS-Login", forHTTPHeaderField: "x-client")
        
        let loginData = HabiticaLoginRequest(username: username, password: password)
        request.httpBody = try JSONEncoder().encode(loginData)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HabiticaAPIError.authenticationFailed
        }
        
        let apiResponse = try JSONDecoder().decode(HabiticaResponse<HabiticaLoginResponse>.self, from: data)
        guard apiResponse.success else {
            throw HabiticaAPIError.apiError(apiResponse.message ?? "Invalid credentials")
        }
        
        return apiResponse.data
    }
    
    // MARK: - Habits
    
    func fetchHabits(userId: String, apiToken: String) async throws -> [HabiticaHabit] {
        let url = URL(string: "\(baseURL)/tasks/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(userId, forHTTPHeaderField: "x-api-user")
        request.addValue(apiToken, forHTTPHeaderField: "x-api-key")
        request.addValue("\(userId)-StrikeChart", forHTTPHeaderField: "x-client")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HabiticaAPIError.fetchFailed
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = "HTTP \(httpResponse.statusCode)"
            // Try to get the actual error response
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Error Response: \(responseString)")
                throw HabiticaAPIError.apiError("\(errorMessage): \(responseString)")
            }
            throw HabiticaAPIError.apiError(errorMessage)
        }
        
        // Debug: Print the raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("API Response JSON: \(responseString)")
            // Also log to NSLog which should appear in device logs
            NSLog("StrikeChart API Response: %@", responseString)
        }
        
        // Try to decode as a generic JSON first to see the structure
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("JSON Structure: \(jsonObject.keys)")
                if let dataArray = jsonObject["data"] as? [[String: Any]] {
                    print("Data array count: \(dataArray.count)")
                    if let firstItem = dataArray.first {
                        print("First item keys: \(firstItem.keys)")
                    }
                }
            }
        } catch {
            print("JSON parsing error: \(error)")
        }
        
        let apiResponse = try JSONDecoder().decode(HabiticaResponse<[HabiticaHabit]>.self, from: data)
        guard apiResponse.success else {
            throw HabiticaAPIError.apiError(apiResponse.message ?? "Unknown error")
        }
        
        return apiResponse.data
    }
    
    // Note: Habitica API doesn't provide individual task history via /tasks/{id}/history
    // History data is only available through /export/history.csv endpoint
    // For now, we create realistic data based on current habit status
}

// MARK: - Error Handling

enum HabiticaAPIError: Error, LocalizedError {
    case authenticationFailed
    case fetchFailed
    case apiError(String)
    case invalidURL
    case noData
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Failed to authenticate with Habitica. Please check your credentials."
        case .fetchFailed:
            return "Failed to fetch data from Habitica."
        case .apiError(let message):
            return "Habitica API Error: \(message)"
        case .invalidURL:
            return "Invalid URL."
        case .noData:
            return "No data received."
        }
    }
}