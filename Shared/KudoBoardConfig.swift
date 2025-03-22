//
//  KudoBoardConfig.swift
//  Testing
//
//  Created by Ricky on 3/22/25.
//

import Foundation

// MARK: - Configuration Struct
struct KudoBoardConfig {
    let boardID: String
    let csrfToken: String
    let cookieHeader: String
    let boundary: String = "----WebKitFormBoundarygUwfH56ejMSaULA4"
}

// MARK: - Service Class
class KudoBoardService {
    private let config: KudoBoardConfig

    init(config: KudoBoardConfig) {
        self.config = config
    }

    func postKudo(message: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://www.kudoboard.com/boards/\(config.boardID)/kudos/create")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = createRawMultipartBody(with: message)
        request.setValue("multipart/form-data; boundary=\(config.boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "x-requested-with")
        request.setValue(csrfToken, forHTTPHeaderField: "x-csrf-token")
        request.setValue("https://www.kudoboard.com", forHTTPHeaderField: "Origin")
        request.setValue("https://www.kudoboard.com/boards/\(config.boardID)/kudos/create", forHTTPHeaderField: "Referer")
        request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
 
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data, let string = String(data: data, encoding: .utf8) {
                print(response)
                completion(.success(string))
            } else {
                completion(.failure(NSError(domain: "Empty response", code: -1)))
            }
        }

        task.resume()
    }

    private func createRawMultipartBody(with message: String) -> Data {
        let boundaryPrefix = "--\(config.boundary)"
        
        let body = """
        \(boundaryPrefix)\r
        Content-Disposition: form-data; name="message"\r
        \r
        <p>\(message)</p>\r
        \(boundaryPrefix)\r
        Content-Disposition: form-data; name="recipients"\r
        \r
        []\r
        \(boundaryPrefix)\r
        Content-Disposition: form-data; name="hashtags"\r
        \r
        undefined\r
        \(boundaryPrefix)\r
        Content-Disposition: form-data; name="custom_fields"\r
        \r
        {}\r
        \(boundaryPrefix)\r
        Content-Disposition: form-data; name="is_private"\r
        \r
        0\r
        \(boundaryPrefix)\r
        Content-Disposition: form-data; name="has_user_created_gif"\r
        \r
        0\r
        \(boundaryPrefix)\r
        Content-Disposition: form-data; name="video_self_recorded"\r
        \r
        0\r
        \(boundaryPrefix)\r
        Content-Disposition: form-data; name="terms_of_service"\r
        \r
        1\r
        \(boundaryPrefix)\r
        Content-Disposition: form-data; name="is_orphan"\r
        \r
        0\r
        \(boundaryPrefix)--\r
        """

        return body.data(using: .utf8)!
    }}
