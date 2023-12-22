//
//  Repository.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/8/23.
//

import Foundation
import Combine

final actor Repository {
    private let asyncCache = AsyncCache<Int, String>()
    private let passThrough = PassthroughSubject<Int, Never>()
    private var passThroughCancellable: AnyCancellable?
    
    //MARK: - Public
    
    init() {
        Task {
            await start()
        }
    }
    
    private func start() async {
        let values = passThrough
            .collect(.byTime(RunLoop.main, .seconds(1.5)))
            .values
        
//            .sink { [weak self] groupedIDs in
        //                guard let self else { return }
        
        Task {
            for await groupedIDs in values {
                do {
                    try await Task.sleep(for: .seconds(2))
                    let values = groupedIDs.map { (value: $0.formatted(), key: $0) }
                    //            await asyncCache.set(values: values)
                    for value in values {
                        await self.asyncCache.setValue(value.value, forKey: value.key)
                    }
                } catch {
                    await self.asyncCache.cancelContinuations(ids: Set(groupedIDs))
                }
            }
        }
    }
    
    func fetch(input: Int) async throws -> String {
//        if Bool.random() {
            passThrough.send(input)
            print("Multiple")
            let v = try await asyncCache.value(for: input)
            print("M \(await asyncCache.cache.count)")
            return v
//        } else {
//            print("Single")
//            let v = try await asyncCache.value(key: input) {
//                try await Task.sleep(for: .seconds(2))
//                return input.formatted()
//            }
//            print("S \(await asyncCache.cache.count)")
//            return v
//        }
    }
}
