//
//  KeyPathComparatorTests.swift
//  FetchRewardsTests
//
//  Created by Richard Witherspoon on 5/25/23.
//  Copyright © 2023 Fetch Rewards, LLC. All rights reserved.
//

import Foundation
import XCTest
@testable import Testing

final class KeyPathComparatorTests: XCTestCase {
    private let items: [Item] = Array(0..<5_000).map { i in
        let title = "\(Int.random(in: 0..<9))_Item"
        
        return Item(
            title: Bool.random() ? title : nil,
            isFavorite: .random(),
            count: .random(in: 0...1000),
            value: Bool.random() ? nil : Int.random(in: 0..<1000)
        )
    }
    
    private struct Item: Equatable {
        let id = UUID()
        let title: String?
        let isFavorite: Bool
        let count: Int
        let value: Int?
    }
    
    
    // MARK: - Tests
    
    func testBoolComparator() {
        let favorites = items.filter{ $0.isFavorite }
        let notFavorites = items.filter{ !$0.isFavorite }
        
        var sorted = items.sorted(using: [
            KeyPathComparator(\.isFavorite, order: .reverse),
            KeyPathComparator(\.count, order: .reverse),
        ])
        
        var fav = favorites.sorted(by: {$0.count > $1.count})
        var notFav = notFavorites.sorted(by: {$0.count > $1.count})
        var expected = fav + notFav
        
        XCTAssertEqual(sorted, expected)
        
        sorted = items.sorted(using: [
            KeyPathComparator(\.isFavorite, order: .forward),
            KeyPathComparator(\.count, order: .reverse),
        ])
        
        fav = favorites.sorted(by: {$0.count > $1.count})
        notFav = notFavorites.sorted(by: {$0.count > $1.count})
        expected = notFav + fav
        
        XCTAssertEqual(sorted, expected)
    }
    
    func testOptionalStringComparator() {
        var sorted = items.sorted(using: [
            KeyPathComparator(\.title, order: .forward, nilOrder: .reverse),
            KeyPathComparator(\.count, order: .reverse),
        ])
        
        let expectedValue = items.filter { $0.title != nil }.sorted(using: [
            KeyPathComparator(\.title, order: .forward),
            KeyPathComparator(\.count, order: .reverse),
        ])
        
        let expectedNil = items.filter { $0.title == nil }.sorted(using: [
            KeyPathComparator(\.title, order: .forward),
            KeyPathComparator(\.count, order: .reverse),
        ])
        
        var expected = expectedValue + expectedNil
        
        XCTAssertEqual(sorted, expected)
        
        sorted = items.sorted(using: [
            KeyPathComparator(\.title, order: .forward, nilOrder: .forward),
            KeyPathComparator(\.count, order: .reverse),
        ])
        
        expected = expectedNil + expectedValue
        
        XCTAssertEqual(sorted, expected)
    }
    
    func testOptionalIntegerComparator() {
        let sorted = items.sorted(using: [
            KeyPathComparator(\.value, order: .forward, nilOrder: .reverse),
            KeyPathComparator(\.count, order: .reverse),
        ])
        
        let expectedValue = items.filter { $0.value != nil }.sorted(using: [
            KeyPathComparator(\.value, order: .forward),
            KeyPathComparator(\.count, order: .reverse),
        ])
        
        let expectedNil = items.filter { $0.value == nil }.sorted(using: [
            KeyPathComparator(\.value, order: .forward),
            KeyPathComparator(\.count, order: .reverse),
        ])
        
        let expected = expectedValue + expectedNil
        
        XCTAssertEqual(sorted, expected)
    }
}
