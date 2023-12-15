//
//  Repository.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/8/23.
//

import Foundation
import Combine

final actor Repository {
    private let channel = AsyncSingleChannel<Int, String>()
    private let passThrough = PassthroughSubject<Int, Never>()
    private var passThroughCancellable: AnyCancellable?
    private let cache = AsyncCache<NSNumber, String>()
    
    //MARK: - Public
    
    init() {
        Task {
            await start()
        }
    }
    
    private func start() async {
        let groupedIDs = await withCheckedContinuation { continuation in
            passThroughCancellable = passThrough
                .collect(.byTime(RunLoop.main, .seconds(1.5)))
                .sink { groupedIDs in
                    continuation.resume(returning: groupedIDs)
                }
        }
        
        do {
            try await Task.sleep(for: .seconds(2))
            
            for id in groupedIDs {
                await self.channel.setValue(id.formatted(), forKey: id)
            }
        } catch {
            await self.channel.cancelContinuations(ids: Set(groupedIDs))
        }
    }
    
    func fetch(input: Int) async throws -> String {
        passThrough.send(input)
        let result = try await channel.value(for: input)
        return result
    }
    
    func fetchCache(input: Int) async throws -> String {
        try await cache.fetch(key: input as NSNumber) {
            try await Task.sleep(for: .seconds(2))
            return input.formatted()
        }
    }
}
