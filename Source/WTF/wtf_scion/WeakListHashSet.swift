/*
 * Copyright (C) 2023 Apple Inc. All rights reserved.
 * Copyright (C) 2026 Scion authors. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

final class WeakListHashSet<T: AnyObject>: Sequence {
  typealias WeakPtrImplSet = ListHashSet<WeakPtr<T>>
  typealias AddResult = WeakPtrImplSet.AddResult

  final class WeakListHashSetIterator: IteratorProtocol, Equatable {
    init(_ set_: WeakListHashSet, _ position: WeakPtrImplSet.iterator) {
      m_set = set_
      m_position = position
      m_beginPosition = set_.m_set.begin()
      m_endPosition = set_.m_set.end()
      skipEmptyBuckets()
    }

    func next() -> T? {
      if m_position == m_endPosition {
        return nil
      }
      let value = *self
      ++m_position
      skipEmptyBuckets()
      m_set.increaseOperationCountSinceLastCleanup()
      return value
    }

    static prefix func * (it: WeakListHashSetIterator) -> T { return *(*it.m_position) }

    @discardableResult
    static prefix func ++ (it: WeakListHashSetIterator) -> WeakListHashSetIterator {
      assert(it.m_position != it.m_endPosition)
      ++it.m_position
      it.skipEmptyBuckets()
      it.m_set.increaseOperationCountSinceLastCleanup()
      return it
    }

    static func == (this: WeakListHashSetIterator, other: WeakListHashSetIterator) -> Bool {
      return this.m_position == other.m_position
    }

    private func skipEmptyBuckets() {
      while m_position != m_endPosition && !(*m_position).bool() {
        ++m_position
      }
    }

    private let m_set: WeakListHashSet
    private let m_position: WeakPtrImplSet.iterator
    private let m_beginPosition: WeakPtrImplSet.iterator
    private let m_endPosition: WeakPtrImplSet.iterator
  }

  func makeIterator() -> WeakListHashSetIterator {
    return WeakListHashSetIterator(self, m_set.begin())
  }

  func begin() -> WeakListHashSetIterator { return makeIterator() }

  func end() -> WeakListHashSetIterator { return WeakListHashSetIterator(self, m_set.end()) }

  func find(value: T) -> WeakListHashSetIterator {
    increaseOperationCountSinceLastCleanup()
    return WeakListHashSetIterator(self, m_set.find(value: WeakPtr(value)))
  }

  func contains(value: T) -> Bool {
    increaseOperationCountSinceLastCleanup()
    return m_set.contains(value: WeakPtr(value))
  }

  @discardableResult
  func add(value: T) -> AddResult {
    amortizedCleanupIfNeeded()
    return m_set.add(value: WeakPtr(value))
  }

  func appendOrMoveToLast(value: T) -> AddResult {
    amortizedCleanupIfNeeded()
    return m_set.appendOrMoveToLast(WeakPtr(value))
  }

  func insertBefore(_ it: WeakListHashSetIterator, _ value: T) -> AddResult {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func remove(value: T) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clear() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmptyIgnoringNullReferences() -> Bool {
    if m_set.isEmpty() {
      return true
    }

    let onlyContainsNullReferences = begin() == end()
    if onlyContainsNullReferences {
      clear()
    }
    return onlyContainsNullReferences
  }

  func computeSize() -> UInt32 {
    removeNullReferences()
    return m_set.size()
  }

  @discardableResult
  private func removeNullReferences() -> Bool {
    var didRemove = false
    let it = m_set.begin()
    while it != m_set.end() {
      let currentIt = it.deepCopy()
      ++it
      if !(*currentIt).bool() {
        m_set.remove(currentIt)
        didRemove = true
      }
    }
    cleanupHappened()
    return didRemove
  }

  func first() -> T {
    let it = begin()
    assert(it != end())
    return *it
  }

  func last() -> T {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func deepCopy() -> WeakListHashSet<T> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func cleanupHappened() {
    m_operationCountSinceLastCleanup = 0
    m_maxOperationCountWithoutCleanup = Swift.min(UInt32.max / 2, m_set.size()) * 2
  }

  @discardableResult
  private func increaseOperationCountSinceLastCleanup(_ count: UInt32 = 1) -> UInt32 {
    m_operationCountSinceLastCleanup += count
    return m_operationCountSinceLastCleanup
  }

  private func amortizedCleanupIfNeeded(_ count: UInt32 = 1) {
    let currentCount = increaseOperationCountSinceLastCleanup(count)
    if currentCount > m_maxOperationCountWithoutCleanup {
      removeNullReferences()
    }
  }

  private let m_set = WeakPtrImplSet()
  private var m_operationCountSinceLastCleanup: UInt32 = 0
  private var m_maxOperationCountWithoutCleanup: UInt32 = 0
}
