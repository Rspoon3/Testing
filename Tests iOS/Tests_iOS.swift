//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by Richard Witherspoon on 8/9/20.
//

import XCTest
@testable import Testing

final class DeviceInfoTests: XCTestCase {
    // MARK: - Tests
    
    func testAllDeviceInputSizesAreUnique() {
        let inputSizes = DeviceInfo.all.map(\.inputSize)
//        let set = Set(inputSizes)
        XCTAssertEqual(inputSizes.count, 4)
    }
}

//extension CGSize: Hashable {
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(width)
//        hasher.combine(height)
//    }
//}
