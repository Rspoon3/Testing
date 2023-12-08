//
//  CacheStatus.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/8/23.
//

import Foundation

enum CacheStatus<T> {
    case inProgress(Task<T, Error>)
    case fetched(T)
}
