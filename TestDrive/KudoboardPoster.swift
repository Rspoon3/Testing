//
//  KudoboardPoster.swift
//  Testing
//
//  Created by Ricky on 3/22/25.
//

import Foundation

final class KudoboardPoster {
    private let loginService: KudoboardLoginService
    private let baseURL = "https://www.kudoboard.com"
    
    var csrfToken: String {
        loginService.csrfToken
    }
    
    var cookies: [HTTPCookie] {
        loginService.cookies
    }
    
    // Store the cookies in a session configuration
    private(set) lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .always
        return URLSession(configuration: configuration)
    }()
    
    init(loginService: KudoboardLoginService) {
        self.loginService = loginService
    }
    
    func postKudo(to boardID: String, messageHTML: String) async throws {
        do {
            try await attemptPost(to: boardID, messageHTML: messageHTML)
        } catch {
            print("❌ First attempt failed. Reauthenticating and retrying...")
            try await loginService.getLoginPage()
            try await loginService.login(email: "richardwitherspoon3@gmail.com", password: "setquc-hipSa3-pykwad")
            try await loginService.visitBoardPage(boardID: boardID)
            try await attemptPost(to: boardID, messageHTML: messageHTML)
        }
    }
    
    private func attemptPost(to boardID: String, messageHTML: String) async throws {
        let boundary = "Boundary-\(UUID().uuidString)"
        let url = URL(string: "\(baseURL)/boards/\(boardID)/kudos/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Headers
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("https://www.kudoboard.com", forHTTPHeaderField: "Origin")
        request.setValue("https://www.kudoboard.com/boards/\(boardID)", forHTTPHeaderField: "Referer")
        
        // Add CSRF token both in header and as form field
        print("Using CSRF token for post: \(self.csrfToken)")
        request.setValue(self.csrfToken, forHTTPHeaderField: "X-CSRF-TOKEN")
        
        // Add all cookies from storage
        let cookieHeaders = HTTPCookie.requestHeaderFields(with: self.cookies)
        for (headerField, value) in cookieHeaders {
            request.setValue(value, forHTTPHeaderField: headerField)
        }
        
        // Debug logging
        print("Sending POST with cookies: \(self.cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; "))")
        
        // Body
        var body = Data()
        
        func appendFormField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Include the CSRF token as a form field (important for Laravel)
        appendFormField(name: "_token", value: self.csrfToken)
        appendFormField(name: "message", value: "<p>\(messageHTML)</p>")
        appendFormField(name: "recipients", value: "[]")
        appendFormField(name: "hashtags", value: "")
        appendFormField(name: "custom_fields", value: "{}")
        appendFormField(name: "is_private", value: "0")
        appendFormField(name: "has_user_created_gif", value: "0")
        appendFormField(name: "video_self_recorded", value: "0")
        appendFormField(name: "terms_of_service", value: "1")
        appendFormField(name: "is_orphan", value: "0")
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KudoboardError.networkError("Invalid HTTP response")
        }
        
        print("POST kudos completed with status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 302 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Success response: \(responseString)")
            }
        } else {
            let responseText = String(data: data, encoding: .utf8) ?? "No body"
            print("Failed response: \(responseText)")
            throw KudoboardError.httpError(httpResponse.statusCode, responseText)
        }
    }
}
