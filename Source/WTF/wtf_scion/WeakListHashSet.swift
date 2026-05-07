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
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    static prefix func * (it: WeakListHashSetIterator) -> T {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    @discardableResult
    static prefix func ++ (it: WeakListHashSetIterator) -> WeakListHashSetIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    static func == (this: WeakListHashSetIterator, other: WeakListHashSetIterator) -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
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

  func begin() -> WeakListHashSetIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func end() -> WeakListHashSetIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func find(value: T) -> WeakListHashSetIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contains(value: T) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func add(value: T) -> AddResult {
    amortizedCleanupIfNeeded()
    return m_set.add(value: WeakPtr(value))
  }

  func appendOrMoveToLast(value: T) -> AddResult {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func first() -> T {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func last() -> T {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func deepCopy() -> WeakListHashSet<T> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func amortizedCleanupIfNeeded(_ count: UInt32 = 1) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let m_set = WeakPtrImplSet()
}
