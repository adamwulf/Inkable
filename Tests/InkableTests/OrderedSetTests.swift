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

    func testRemoveOne() throws {
        var set = OrderedIndexSet()

        set.append(0)
        set.append(contentsOf: [1, 2])
        set.remove(at: 1)

        XCTAssertEqual(set.count, 2)
        XCTAssert(set.contains(0))
        XCTAssert(set.contains(2))
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

    func testInsertAt() throws {
        var set = OrderedIndexSet()

        set.append(contentsOf: [1, 2, 3])
        set.insert(4, at: 1)

        XCTAssertEqual(set.count, 4)
        XCTAssert(set.contains(1))
        XCTAssert(set.contains(2))
        XCTAssert(set.contains(3))
        XCTAssert(set.contains(4))
        XCTAssertEqual(set[1], 4)
        XCTAssertEqual(set.index(of: 4), 1)
    }

    func testInsertSome() throws {
        var set = OrderedIndexSet()

        set.append(contentsOf: [1, 2, 3])
        set.insert(contentsOf: [4, 5], at: 1)

        XCTAssertEqual(set.count, 5)
        XCTAssert(set.contains(1))
        XCTAssert(set.contains(2))
        XCTAssert(set.contains(3))
        XCTAssert(set.contains(4))
        XCTAssert(set.contains(5))
        XCTAssertEqual(set[1], 4)
        XCTAssertEqual(set[2], 5)
        XCTAssertEqual(set.index(of: 4), 1)
        XCTAssertEqual(set.index(of: 5), 2)
    }
}
