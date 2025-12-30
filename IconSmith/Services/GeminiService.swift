import Foundation
import AppKit
import Security

@MainActor
final class GeminiService: ObservableObject {
    @Published var hasAPIKey: Bool = false
    
    private var apiKey: String? {
        didSet { hasAPIKey = apiKey != nil && !apiKey!.isEmpty }
    }
    
    enum GeminiError: LocalizedError {
        case noAPIKey
        case invalidResponse
        case imageDecodingFailed
        case apiError(String)
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No API key configured"
            case .invalidResponse:
                return "Invalid response from Gemini API"
            case .imageDecodingFailed:
                return "Failed to decode generated image"
            case .apiError(let message):
                return "API error: \(message)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    enum Style: String, CaseIterable, Identifiable {
        case bigSur = "macOS Big Sur"
        case flat = "Flat"
        case outlined = "Outlined"
        case glyph = "Glyph"
        
        var id: String { rawValue }
        
        var prompt: String {
            switch self {
            case .bigSur:
                return "macOS Big Sur style with rounded corners and soft gradients"
            case .flat:
                return "flat design with solid colors and minimal detail"
            case .outlined:
                return "outlined icon with thin strokes"
            case .glyph:
                return "simple monochrome glyph symbol"
            }
        }
    }
    
    struct GenerationRequest {
        var prompt: String
        var style: Style
        var accentColor: String?
    }
    
    private let keychainService = "com.nicobailon.IconSmith"
    private let keychainAccount = "gemini-api-key"
    
    init() {
        loadAPIKey()
    }
    
    func setAPIKey(_ key: String) {
        apiKey = key
        saveAPIKeyToKeychain(key)
    }
    
    func clearAPIKey() {
        apiKey = nil
        deleteAPIKeyFromKeychain()
    }
    
    func generateIcon(_ request: GenerationRequest) async throws -> NSImage {
        guard let apiKey = apiKey else {
            throw GeminiError.noAPIKey
        }
        
        let fullPrompt = buildPrompt(request)
        
        var urlComponents = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent")!
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [["parts": [["text": fullPrompt]]]],
            "generationConfig": [
                "responseModalities": ["IMAGE", "TEXT"],
                "candidateCount": 1
            ]
        ]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw GeminiError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.apiError(errorMsg)
        }
        
        return try parseImageResponse(data)
    }
    
    private func buildPrompt(_ request: GenerationRequest) -> String {
        var prompt = "Create a file type icon: \(request.prompt). "
        prompt += "Style: \(request.style.prompt). "
        prompt += "The icon should be square, centered, with a transparent or simple background suitable for use as a macOS file icon. "
        
        if let color = request.accentColor {
            prompt += "Use \(color) as the primary accent color. "
        }
        
        prompt += "High quality, crisp edges, professional appearance. Output a single icon image."
        return prompt
    }
    
    private func parseImageResponse(_ data: Data) throws -> NSImage {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw GeminiError.invalidResponse
        }
        
        for part in parts {
            if let inlineData = part["inlineData"] as? [String: Any],
               let base64String = inlineData["data"] as? String,
               let imageData = Data(base64Encoded: base64String),
               let image = NSImage(data: imageData) {
                return image
            }
        }
        
        throw GeminiError.imageDecodingFailed
    }
    
    private func loadAPIKey() {
        apiKey = loadAPIKeyFromKeychain()
    }
    
    private func saveAPIKeyToKeychain(_ key: String) {
        deleteAPIKeyFromKeychain()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: key.data(using: .utf8)!
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadAPIKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    private func deleteAPIKeyFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
