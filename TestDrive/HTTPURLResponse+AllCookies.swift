//
//  HTTPURLResponse+AllCookies.swift
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
