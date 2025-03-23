//
//  KudoboardError.swift
//  Testing
//
//  Created by Ricky on 3/22/25.
//

import Foundation

// Extend URLResponse to help extract cookies
extension HTTPURLResponse {
    func allCookies() -> [HTTPCookie] {
        let headerFields = self.allHeaderFields as! [String: String]
        return HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: self.url!)
    }
}

enum KudoboardError: Error {
    case networkError(String)
    case jsonParsingError(String)
    case loginFailed(String)
    case csrfTokenNotFound
    case httpError(Int, String)
}

actor KudoboardLoginService {
    private let baseURL = "https://www.kudoboard.com"
    private var cookies: [HTTPCookie] = []
    var csrfToken: String = ""
    
    // Store the cookies in a session configuration
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .always
        return URLSession(configuration: configuration)
    }()
    
    // Step 1: Make GET request to login page to get cookies and CSRF token
    func getLoginPage() async throws {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw KudoboardError.networkError("Invalid HTTP response")
            }
            
            // Extract cookies from response
            let responseCookies = httpResponse.allCookies()
            self.cookies.append(contentsOf: responseCookies)
            
            // Store cookies in the cookie storage
            HTTPCookieStorage.shared.setCookies(responseCookies, for: url, mainDocumentURL: nil)
            
            // Try to extract CSRF token from response data or cookies
            if let htmlString = String(data: data, encoding: .utf8) {
                self.extractCSRFToken(from: htmlString)
            }
            
            // Look for XSRF-TOKEN in cookies if not found in HTML
            if self.csrfToken.isEmpty {
                for cookie in responseCookies {
                    if cookie.name == "XSRF-TOKEN" {
                        if let value = cookie.value.removingPercentEncoding {
                            self.csrfToken = value
                        }
                    }
                }
            }
            
            print("GET request completed with status code: \(httpResponse.statusCode)")
            print("Cookies obtained: \(self.cookies.map { $0.name })")
            print("CSRF Token: \(self.csrfToken)")
            
            // Check if we have a token
            if self.csrfToken.isEmpty {
                throw KudoboardError.csrfTokenNotFound
            }
            
        } catch let error as KudoboardError {
            throw error
        } catch {
            throw KudoboardError.networkError(error.localizedDescription)
        }
    }
    
    // Extract CSRF token from HTML
    private func extractCSRFToken(from html: String) {
        // Look for meta tag with name="csrf-token"
        if let range = html.range(of: #"<meta name="csrf-token" content="([^"]+)""#, options: .regularExpression) {
            let metaTag = html[range]
            if let tokenRange = metaTag.range(of: #"content="([^"]+)""#, options: .regularExpression) {
                let tokenPart = metaTag[tokenRange]
                if let actualTokenRange = tokenPart.range(of: #""([^"]+)""#, options: .regularExpression) {
                    let token = tokenPart[actualTokenRange]
                    // Remove quotes
                    self.csrfToken = String(token).replacingOccurrences(of: "\"", with: "")
                }
            }
        }
        
        // If not found in meta tag, look for JavaScript variable
        if self.csrfToken.isEmpty {
            let pattern = #"_token\s*=\s*['"]([^'"]+)['"]"#
            if let range = html.range(of: pattern, options: .regularExpression) {
                let match = html[range]
                if let valueRange = match.range(of: #"['"]([^'"]+)['"]"#, options: .regularExpression) {
                    let valueMatch = match[valueRange]
                    self.csrfToken = String(valueMatch).replacingOccurrences(of: #"['"](.*)['"]{1}"#, with: "$1", options: .regularExpression)
                }
            }
        }
    }
    
    // Step 2: Make POST request to login
    func login(email: String, password: String) async throws {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers
        request.setValue(csrfToken, forHTTPHeaderField: "X-CSRF-TOKEN")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("https://www.kudoboard.com", forHTTPHeaderField: "Origin")
        request.setValue("https://www.kudoboard.com/auth/login", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 13_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        // Add cookies to the request
        let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookies)
        for (headerField, value) in cookieHeaders {
            request.setValue(value, forHTTPHeaderField: headerField)
        }
        
        // Prepare login data
        let loginData: [String: Any] = [
            "email": email,
            "password": password,
            "remember": true,
            "alt_logins": true
        ]
        
        // Convert login data to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        } catch {
            throw KudoboardError.jsonParsingError(error.localizedDescription)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw KudoboardError.networkError("Invalid HTTP response")
            }
            
            print("POST request completed with status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                
                let stringData = String(data: data, encoding: .utf8)
                print("POST request response: \(stringData ?? "No data returned")")
                
                // Parse the JSON response
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let success = jsonResponse["success"] as? Bool, success {
                            
                            // Print user info if available
                            if let user = jsonResponse["user"] as? [String: Any] {
                                print("Login successful for user: \(user["email"] ?? "Unknown")")
                            }
                            
                            // Replace old cookies entirely
                            let newCookies = httpResponse.allCookies()
                            if !newCookies.isEmpty {
                                self.cookies = newCookies
                                HTTPCookieStorage.shared.setCookies(newCookies, for: url, mainDocumentURL: nil)

                                // Update CSRF token from new cookies
                                if let xsrfCookie = newCookies.first(where: { $0.name == "XSRF-TOKEN" }) {
                                    self.csrfToken = xsrfCookie.value.removingPercentEncoding ?? xsrfCookie.value
                                }

                                print("✅ Cookies updated: \(newCookies.map { $0.name })")
                                print("✅ New CSRF token: \(self.csrfToken)")
                            }
                        } else {
                            print("------")
                            print(jsonResponse)
                            print("------")
                            throw KudoboardError.loginFailed("Login failed")
                        }
                    }
                } catch let error as KudoboardError {
                    throw error
                } catch {
                    throw KudoboardError.jsonParsingError(error.localizedDescription)
                }
            } else {
                throw KudoboardError.httpError(httpResponse.statusCode, "HTTP error")
            }
        } catch let error as KudoboardError {
            throw error
        } catch {
            throw KudoboardError.networkError(error.localizedDescription)
        }
    }
    
    // Step 3: Visit the board page to get a fresh CSRF token
    func visitBoardPage(boardID: String) async throws {
        let url = URL(string: "\(baseURL)/boards/\(boardID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add cookies to request
        let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookies)
        for (headerField, value) in cookieHeaders {
            request.setValue(value, forHTTPHeaderField: headerField)
        }
        
        // Set up other headers for a typical browser request
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 13_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw KudoboardError.networkError("Invalid HTTP response")
            }
            
            print("Board page visit completed with status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                // Update cookies from response
                let newCookies = httpResponse.allCookies()
                if !newCookies.isEmpty {
                    self.cookies = newCookies
                    HTTPCookieStorage.shared.setCookies(newCookies, for: url, mainDocumentURL: nil)
                
                    // Update CSRF token from cookies
                    if let xsrfCookie = newCookies.first(where: { $0.name == "XSRF-TOKEN" }) {
                        self.csrfToken = xsrfCookie.value.removingPercentEncoding ?? xsrfCookie.value
                        print("✅ Updated CSRF token from board page: \(self.csrfToken)")
                    }
                }
                
                // Also try to extract CSRF token from HTML if available
                if let htmlString = String(data: data, encoding: .utf8) {
                    let oldToken = self.csrfToken
                    self.extractCSRFToken(from: htmlString)
                    if self.csrfToken != oldToken {
                        print("✅ Updated CSRF token from HTML: \(self.csrfToken)")
                    }
                }
            } else {
                throw KudoboardError.httpError(httpResponse.statusCode, "Failed to load board page")
            }
        } catch let error as KudoboardError {
            throw error
        } catch {
            throw KudoboardError.networkError(error.localizedDescription)
        }
    }
    
    // Step 4: Post kudo to the board
    func postKudo(to boardID: String, messageHTML: String) async throws {
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
        appendFormField(name: "message", value: messageHTML)
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
        
        do {
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
        } catch let error as KudoboardError {
            throw error
        } catch {
            throw KudoboardError.networkError(error.localizedDescription)
        }
    }
}
