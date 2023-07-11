//
//  UserDefaults+Extension.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 7/11/23.
//

import Foundation


extension UserDefaults {
    public static var shared: UserDefaults {
        return UserDefaults(suiteName: "group.com.rspoon3.Testing2")!
    }
}
