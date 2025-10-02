import Foundation

// Simple test to verify your API key works
// Run this in a playground or add to your app temporarily

func testOpenAIKey() async {
    let apiKey = "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"
    
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body: [String: Any] = [
        "model": "gpt-3.5-turbo",
        "messages": [["role": "user", "content": "Say hello"]],
        "max_tokens": 10
    ]
    
    request.httpBody = try! JSONSerialization.data(withJSONObject: body)
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
            if let responseText = String(data: data, encoding: .utf8) {
                print("Response: \(responseText)")
            }
        }
    } catch {
        print("Error: \(error)")
    }
}

