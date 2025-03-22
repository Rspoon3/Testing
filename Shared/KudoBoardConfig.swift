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
