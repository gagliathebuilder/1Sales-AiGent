import Foundation
import Alamofire

class OpenAIService: ObservableObject {
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let apiKey: String
    
    @Published var isLoading = false
    
    init() {
        // In production, you should store this securely
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            fatalError("OpenAI API key not found")
        }
        self.apiKey = apiKey
    }
    
    func generateSalesCoachingResponse(for text: String) async throws -> String {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        
        let prompt = """
        As an expert sales coach, analyze the following sales conversation and provide specific, 
        actionable feedback on how to improve the approach, handling objections, and closing techniques. 
        Focus on both strengths and areas for improvement:
        
        Sales Representative: \(text)
        """
        
        let parameters: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are an expert sales coach with years of experience in training top-performing sales professionals."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(endpoint, 
                      method: .post, 
                      parameters: parameters, 
                      encoding: JSONEncoding.default, 
                      headers: headers)
                .responseDecodable(of: OpenAIResponse.self) { response in
                    switch response.result {
                    case .success(let openAIResponse):
                        if let content = openAIResponse.choices.first?.message.content {
                            continuation.resume(returning: content)
                        } else {
                            continuation.resume(throwing: OpenAIError.noResponseContent)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
}

struct OpenAIResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
    }
    
    struct Message: Decodable {
        let content: String
    }
}

enum OpenAIError: Error {
    case noResponseContent
} 