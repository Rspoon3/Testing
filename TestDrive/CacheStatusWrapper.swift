//
//  CacheStatusWrapper.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/8/23.
//

import Foundation

final class CacheStatusWrapper<T> {
    let status: CacheStatus<T>
    
    init(_ status: CacheStatus<T>) {
        self.status = status
    }
}
