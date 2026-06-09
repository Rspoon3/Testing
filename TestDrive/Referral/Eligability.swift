//
//  Eligability.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 6/5/26.
//

import Foundation

/// The backend's verdict on whether a referral code can be used.
enum Eligability: Codable, Equatable {
    /// The code is valid and may be used.
    case valid

    /// The code is invalid and may not be used.
    case invalid
}
