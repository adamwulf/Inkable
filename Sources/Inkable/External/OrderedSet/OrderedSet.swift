/*
 This source file is part of the Swift.org open source project
 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception
 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

/*
 * This source file was modified on 4/4/2021 by Adam Wulf in accordance
 * with the Apache 2.0 license. See the original source code at:
 * https://github.com/apple/swift-package-manager/blob/5d05348c6fd072ae7989ed8b55ac2b017486acf4/Sources/Basic/OrderedSet.swift
 */

/// An ordered set is an ordered collection of instances of `Element` in which
/// uniqueness of the objects is guaranteed.
public struct OrderedSet<E: Hashable>: Equatable, Collection {
    public typealias Element = E
    public typealias Index = Int

  #if swift(>=4.1.50)
    public typealias Indices = Range<Int>
  #else
    public typealias Indices = CountableRange<Int>
  #endif

    private var array: [Element]
    private var set: Set<Element>

    /// Creates an empty ordered set.
    public init() {
        self.array = []
        self.set = Set()
    }

    /// Creates an ordered set with the contents of `array`.
    ///
    /// If an element occurs more than once in `element`, only the first one
    /// will be included.
    public init(_ array: [Element]) {
        self.init()
        for element in array {
            append(element)
        }
    }

    // MARK: Working with an ordered set
    /// The number of elements the ordered set stores.
    public var count: Int { return array.count }

    /// Returns `true` if the set is empty.
    public var isEmpty: Bool { return array.isEmpty }

    /// Returns the contents of the set as an array.
    public var contents: [Element] { return array }

    /// Returns `true` if the ordered set contains `member`.
    public func contains(_ member: Element) -> Bool {
        return set.contains(member)
    }

    /// Adds an element to the ordered set.
    ///
    /// If it already contains the element, then the set is unchanged.
    ///
    /// - returns: True if the item was inserted.
    @discardableResult
    public mutating func append(_ newElement: Element) -> Bool {
        let inserted = set.insert(newElement).inserted
        if inserted {
            array.append(newElement)
        }
        return inserted
    }

    @discardableResult
    public mutating func append(contentsOf elements: [Element]) -> Bool {
        var insertedAny = false
        for newElement in elements {
            let insertedOne = set.insert(newElement).inserted
            if insertedOne {
                array.append(newElement)
            }
            insertedAny = insertedAny || insertedOne
        }
        return insertedAny
    }

    @discardableResult
    public mutating func insert(_ newElement: Element, at index: Index) -> Bool {
        let inserted = set.insert(newElement).inserted
        if inserted {
            array.insert(newElement, at: index)
        }
        return inserted
    }

    @discardableResult
    public mutating func insert(contentsOf elements: [Element], at index: Index) -> Bool {
        let inserted = elements.filter({ set.insert($0).inserted })
        if !inserted.isEmpty {
            array.insert(contentsOf: inserted, at: index)
        }
        return !inserted.isEmpty
    }

    /// Remove and return the element at the beginning of the ordered set.
    public mutating func removeFirst() -> Element {
        let firstElement = array.removeFirst()
        set.remove(firstElement)
        return firstElement
    }

    /// Remove and return the element at the end of the ordered set.
    public mutating func removeLast() -> Element {
        let lastElement = array.removeLast()
        set.remove(lastElement)
        return lastElement
    }

    /// Remove all elements.
    public mutating func removeAll(keepingCapacity keepCapacity: Bool) {
        array.removeAll(keepingCapacity: keepCapacity)
        set.removeAll(keepingCapacity: keepCapacity)
    }
}

extension OrderedSet {
    public func index(of element: Element) -> Index? {
        return array.firstIndex(of: element)
    }

    public mutating func remove(_ element: Element) {
        guard let index = index(of: element) else { return }
        array.remove(at: index)
        set.remove(element)
    }

    public mutating func remove(at index: Index) {
        let element = array[index]
        array.remove(at: index)
        set.remove(element)
    }

    public mutating func replace(at index: Index, with elements: [Element]) {
        let element = self[index]
        set.remove(element)
        let elements = elements.compactMap({ set.insert($0).inserted ? $0 : nil })
        array.replaceSubrange(index ..< index + 1, with: elements)
    }

    public mutating func replace(element: Element, with elements: [Element]) {
        guard let index = index(of: element) else { return }
        set.remove(element)
        let elements = elements.compactMap({ set.insert($0).inserted ? $0 : nil })
        array.replaceSubrange(index ..< index + 1, with: elements)
    }

    public mutating func replaceSubrange(_ range: Range<Index>, with elements: [Element]) {
        let toRemove = range.map({ self[$0] })
        toRemove.forEach({ set.remove($0) })
        let elements = elements.compactMap({ set.insert($0).inserted ? $0 : nil })
        array.replaceSubrange(range, with: elements)
    }
}

extension OrderedSet: ExpressibleByArrayLiteral {
    /// Create an instance initialized with `elements`.
    ///
    /// If an element occurs more than once in `element`, only the first one
    /// will be included.
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension OrderedSet: RandomAccessCollection {
    public var startIndex: Int { return contents.startIndex }
    public var endIndex: Int { return contents.endIndex }
    public subscript(index: Int) -> Element {
      return contents[index]
    }
}

public func == <T>(lhs: OrderedSet<T>, rhs: OrderedSet<T>) -> Bool {
    return lhs.contents == rhs.contents
}

extension OrderedSet: Hashable where Element: Hashable { }
