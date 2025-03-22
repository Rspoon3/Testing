//
//  WebViewWrapper.swift
//  Testing
//
//  Created by Ricky on 3/22/25.
//


import SwiftUI
import WebKit

// MARK: - WebViewWrapper
struct WebViewWrapper: NSViewRepresentable {
    let webView = WKWebView()
    let onCookiesExtracted: ([HTTPCookie]) -> Void

    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator

        // Load your Kudoboard URL here
        if let url = URL(string: "https://www.kudoboard.com/boards/BDk2ACtk") {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCookiesExtracted: onCookiesExtracted)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onCookiesExtracted: ([HTTPCookie]) -> Void

        init(onCookiesExtracted: @escaping ([HTTPCookie]) -> Void) {
            self.onCookiesExtracted = onCookiesExtracted
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                self.onCookiesExtracted(cookies)
            }
        }
    }
}

// MARK: - WebViewScreen
struct WebViewScreen: View {
    @State private var csrfToken: String? = nil
    @State private var cookieHeader: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            if let csrf = csrfToken, let cookies = cookieHeader {
                Text("✅ Tokens extracted!")
                    .font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("x-csrf-token:")
                            .bold()
                        Text(csrf)
                            .font(.system(size: 12, design: .monospaced))
                        
                        Button("📋 Copy CSRF Token") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(csrf, forType: .string)
                        }
                        
                        Text("\nCookie Header:")
                            .bold()
                        Text(cookies)
                            .font(.system(size: 12, design: .monospaced))
                        
                        Button("📋 Copy Cookie Header") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(cookies, forType: .string)
                        }
                    }
                }
                .padding()
            } else {
                Text("🔐 Log in to Kudoboard to extract auth cookies...")
                    .padding(.bottom)
                WebViewWrapper { cookies in
                    let token = extractRawXSRFToken(from: cookies)
                    let sessionCookies = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")

                    if let token = token {
                        self.csrfToken = decodeXSRFToken(token)
                        self.cookieHeader = sessionCookies
                    }
                }
                .frame(minHeight: 500)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 600)
    }
    
    func extractRawXSRFToken(from cookies: [HTTPCookie]) -> String? {
        cookies.first(where: { $0.name == "XSRF-TOKEN" })?.value.removingPercentEncoding
    }

    private func decodeXSRFToken(_ token: String) -> String? {
        // First: URL decode it
        guard let urlDecoded = token.removingPercentEncoding else {
            print("❌ Could not URL decode")
            return nil
        }

        // Then: base64 decode it
        guard let data = Data(base64Encoded: urlDecoded) else {
            print("❌ Could not base64 decode")
            return nil
        }

        // Try parsing JSON to extract the actual CSRF token
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let value = json["value"] as? String {
                return value
            }
        } catch {
            print("❌ JSON parsing error: \(error)")
        }

        return nil
    }
}
