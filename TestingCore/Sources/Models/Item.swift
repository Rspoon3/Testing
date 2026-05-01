//
//  DeviceInfo.swift
//  Testing
//
//  Created by Richard Witherspoon on 4/19/23.
//

import Foundation

public struct Item {
    
#if DEBUG
    public let title = "Debug"
#else
    public let title = "Else Block"
#endif
    
    public init() {}
}
