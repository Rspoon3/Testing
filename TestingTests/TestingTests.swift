//
//  TestingTests.swift
//  TestingTests
//
//  Created by Richard Witherspoon on 1/20/23.
//

import XCTest
import Combine
@testable import Testing

class OrthogonalUICollectionViewModelTests: XCTestCase {
    var sut: ContentViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        sut = ContentViewModel(timer: MockTimer())
        cancellables = []
    }
    
    func testDoesScroll() {
        var didScroll = false
        sut.shouldAutoScroll
            .receive(on: ImmediateScheduler.shared)
            .sink { _ in
                didScroll = true
                print("didScroll to true")
            }.store(in: &cancellables)
        
        sut.restartTimer()
        
        XCTAssertTrue(didScroll)
    }
}

