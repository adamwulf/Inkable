//
//  MinMaxIndex.swift
//  
//
//  Created by Adam Wulf on 7/2/22.
//

import Foundation

/// Represents a range of Int indexes
public struct MinMaxIndex: Equatable {
    private var start: Int
    private var end: Int

    public static let null = MinMaxIndex()

    public init() {
        start = .max
        end = .max
    }

    public init(_ indexes: ClosedRange<Int>) {
        guard let first = indexes.first, let last = indexes.last else { self = .null; return }
        start = first
        end = last
    }

    public init(_ indexes: Range<Int>) {
        guard let first = indexes.first, let last = indexes.last else { self = .null; return }
        start = first
        end = last
    }

    public init(_ integers: [Int]) {
        guard !integers.isEmpty else { self = .null; return }
        start = integers.min()!
        end = integers.max()!
    }

    public init(_ integer: Int) {
        start = integer
        end = integer
    }

    public init(_ indexSet: IndexSet) {
        guard !indexSet.isEmpty else { self = .null; return }
        start = indexSet.min()!
        end = indexSet.max()!
    }

    public var count: Int {
        guard self != .null else { return 0 }
        return end - start + 1
    }

    public var first: Int? {
        guard self != .null else { return nil }
        return start
    }

    public var last: Int? {
        guard self != .null else { return nil }
        return end
    }

    @inlinable @inline(__always)
    public func asIndexSet() -> IndexSet {
        guard let first = first, let last = last else { return IndexSet() }
        return IndexSet(integersIn: first...last)
    }

    public mutating func insert(_ index: Int) {
        if self == Self.null {
            start = index
            end = index
        } else {
            start = Swift.min(start, index)
            end = Swift.max(end, index)
        }
    }

    @inlinable @inline(__always)
    public mutating func insert(integersIn indexes: ClosedRange<Int>) {
        guard let first = indexes.first, let last = indexes.last else { return }
        insert(first)
        insert(last)
    }

    public mutating func remove(_ index: Int) {
        if start == index {
            start += 1
        }
        if end == index {
            end -= 1
        }
        if start > end {
            start = .max
            end = .max
        }
    }

    @inlinable @inline(__always)
    public func contains(_ index: Int) -> Bool {
        guard let first = first, let last = last else { return false }
        return index >= first && index <= last
    }
}

extension MinMaxIndex: Sequence {
    public func makeIterator() -> Iterator {
        return Iterator(min: start, max: end)
    }

    public struct Iterator: IteratorProtocol {
        public typealias Element = Int

        var min: Int
        let max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        public mutating func next() -> Int? {
            if min == max, min == .max {
                return nil
            } else if min > max {
                return nil
            } else {
                let ret = min
                min += 1
                return ret
            }
        }
    }
}
