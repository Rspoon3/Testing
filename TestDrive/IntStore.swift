//
//  IntStore.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/18/25.
//


import Foundation
import Combine

public final class IntStore: InMemoryStore<Int>, ObservableObject {
    static let shared = IntStore()
    private var cancellable: AnyCancellable?

    private init() {
        super.init(initialValue: 0)
        
          cancellable = publisher
              .sink { [weak self] _ in
                  self?.objectWillChange.send()
              }
    }
}
