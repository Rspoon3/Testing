//
//  MultiDataStore.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/18/25.
//

import Foundation
import Combine

final class MultiDataStore: InMemoryStore<MultiData> {
    static let shared = MultiDataStore()

    private init() {
        super.init(initialValue: MultiData(int: 0, string: "", bool: false))
    }

    // MARK: - Individual Accessors via KeyPaths

//    var int: Int {
//        get { self[\.int] }
//        set { self[\.int] = newValue }
//    }
//
//    var string: String {
//        get { self[\.string] }
//        set { self[\.string] = newValue }
//    }
//
//    var bool: Bool {
//        get { self[\.bool] }
//        set { self[\.bool] = newValue }
//    }
}
