//
//  KudoboardError.swift
//  Testing
//
//  Created by Ricky on 3/22/25.
//

import Foundation

enum KudoboardError: Error {
    case networkError(String)
    case loginFailed(String)
    case csrfTokenNotFound
    case httpError(Int, String)
}
