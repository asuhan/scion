/*
 * Copyright (C) 2005-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2011, Benjamin Poulain <ikipou@gmail.com>
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

final class ListHashSetIterator<T>: IteratorProtocol, Equatable {
  func next() -> T? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static prefix func * (it: ListHashSetIterator<T>) -> T {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  static prefix func ++ (it: ListHashSetIterator<T>) -> ListHashSetIterator<T> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  static prefix func -- (it: ListHashSetIterator<T>) -> ListHashSetIterator<T> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func == (this: ListHashSetIterator<T>, other: ListHashSetIterator<T>) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

final class ListHashSet<T: Equatable & Hashable>: Sequence {
  init() {}

  struct AddResult {
    let isNewEntry: Bool
  }

  func size() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmpty() -> Bool { return m_impl.isEmpty }

  func begin() -> ListHashSetIterator<T> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func end() -> ListHashSetIterator<T> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contains(value: T) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func add(value: T) -> AddResult {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func last() -> T {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func find(value: T) -> ListHashSetIterator<T> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func makeIterator() -> ListHashSetIterator<T> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let m_impl = Set<T>()
}
