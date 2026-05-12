/*
 * Copyright (C) 2021 Apple Inc. All rights reserved.
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

final class WeakHashMap<KeyType: AnyObject, ValueType> {
  struct AddResult {
    let isNewEntry: Bool
    let value: ValueType
  }

  func ensure(_ key: KeyType, _ functor: () -> ValueType) -> AddResult {
    let objId = ObjectIdentifier(key)
    if let value = m_impl[objId] {
      return AddResult(isNewEntry: false, value: value)
    }
    m_impl[objId] = functor()
    return AddResult(isNewEntry: true, value: functor())
  }

  func add(_ key: KeyType, _ value: ValueType) -> AddResult {
    return ensure(key, { () in return value })
  }

  func get(_ key: KeyType, _ defaultValue: ValueType) -> ValueType {
    return m_impl[ObjectIdentifier(key)] ?? defaultValue
  }

  func contains(_ key: KeyType) -> Bool {
    increaseOperationCountSinceLastCleanup()
    return m_impl[ObjectIdentifier(key)] != nil
  }

  @discardableResult
  func increaseOperationCountSinceLastCleanup(_ operationsPerformed: UInt32 = 1) -> UInt32 {
    let currentCount = m_operationCountSinceLastCleanup
    m_operationCountSinceLastCleanup += operationsPerformed
    return currentCount
  }

  private var m_impl: [ObjectIdentifier: ValueType] = [:]
  private var m_operationCountSinceLastCleanup: UInt32 = 0
}
