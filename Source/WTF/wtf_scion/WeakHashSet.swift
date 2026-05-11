/*
 * Copyright (C) 2017-2020 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

final class WeakHashSet<KeyType: AnyObject>: Sequence, IteratorProtocol {
  typealias WeakPtrImplSet = HashSet<WeakPtr<KeyType>>
  typealias AddResult = WeakPtrImplSet.AddResult

  @discardableResult
  func add(value: KeyType) -> AddResult {
    amortizedCleanupIfNeeded()
    return m_set.add(WeakPtr(value))
  }

  func remove(_ value: KeyType) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clear() {
    m_set.clear()
    cleanupHappened()
  }

  func contains(value: KeyType) -> Bool {
    increaseOperationCountSinceLastCleanup()
    return m_set.contains(value: WeakPtr(value))
  }

  func isEmptyIgnoringNullReferences() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeSize() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func next() -> KeyType? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func cleanupHappened() {
    m_operationCountSinceLastCleanup = 0
    m_maxOperationCountWithoutCleanup = Swift.min(UInt32.max / 2, m_set.size()) * 2
  }

  @discardableResult
  private func removeNullReferences() -> Bool {
    let didRemove = m_set.remove(WeakPtr<KeyType>(nil))
    cleanupHappened()
    return didRemove
  }

  @discardableResult
  private func increaseOperationCountSinceLastCleanup(_ count: UInt32 = 1) -> UInt32 {
    m_operationCountSinceLastCleanup += count
    return m_operationCountSinceLastCleanup
  }

  private func amortizedCleanupIfNeeded() {
    let currentCount = increaseOperationCountSinceLastCleanup()
    if currentCount > m_maxOperationCountWithoutCleanup {
      removeNullReferences()
    }
  }

  private let m_set = WeakPtrImplSet()
  private var m_operationCountSinceLastCleanup: UInt32 = 0
  private var m_maxOperationCountWithoutCleanup: UInt32 = 0
}

func copyToVector<T>(collection: WeakHashSet<T>) -> [WeakRef<T>] {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
