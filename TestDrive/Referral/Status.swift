//
//  Status.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 6/5/26.
//

import Foundation

/// Whether a referral code has been resolved by the backend yet.
enum Status: Codable, Equatable {
    /// The backend has not yet returned an eligibility response.
    case unresolved

    /// The backend has returned an eligibility response.
    case resolved(Eligability)
}
