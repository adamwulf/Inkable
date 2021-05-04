//
//  OrderedSetTests.swift
//  InkableTests
//
//  Created by Adam Wulf on 5/1/21.
//

import XCTest
@testable import Inkable

class OrderedSetTests: XCTestCase {
    public typealias OrderedIndexSet = OrderedSet<Int>

    func testReplaceOne() throws {
        var set = OrderedIndexSet()

        set.append(0)
        set.replace(at: 0, with: Array(2..<4))

        XCTAssertEqual(set.count, 2)
        XCTAssertFalse(set.contains(0))
        XCTAssert(set.contains(2))
        XCTAssert(set.contains(3))
    }

    func testReplaceRange() throws {
        var set = OrderedIndexSet()

        set.append(10)
        set.append(11)
        set.replaceSubrange(0..<2, with: [12, 13])

        XCTAssertEqual(set.count, 2)
        XCTAssertFalse(set.contains(10))
        XCTAssertFalse(set.contains(11))
        XCTAssert(set.contains(12))
        XCTAssert(set.contains(13))
    }
}
