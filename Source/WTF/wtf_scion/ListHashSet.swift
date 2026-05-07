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

final class ListHashSetIterator<T: Equatable & Hashable>: IteratorProtocol, Equatable {
  typealias ListHashSetType = ListHashSet<T>
  typealias Node = ListHashSetNode<T>

  init(_ set_: ListHashSetType, _ position: Node?) {
    m_set = set_
    m_position = position
  }

  func next() -> T? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static prefix func * (it: ListHashSetIterator<T>) -> T { return it.m_position!.m_value }

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

  // Comparison.
  static func == (this: ListHashSetIterator<T>, other: ListHashSetIterator<T>) -> Bool {
    return this.m_position === other.m_position
  }

  private let m_set: ListHashSetType?
  private let m_position: Node?
}

final class ListHashSet<T: Equatable & Hashable>: Sequence {
  private typealias Node = ListHashSetNode<T>

  typealias iterator = ListHashSetIterator<T>

  init() {}

  struct AddResult {
    let isNewEntry: Bool
  }

  func size() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmpty() -> Bool { return m_impl.isEmpty }

  func begin() -> ListHashSetIterator<T> { return makeIterator(m_head) }

  func end() -> ListHashSetIterator<T> { return makeIterator(nil) }

  func contains(value: T) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func add(value: T) -> AddResult {
    let (isNewEntry, _) = m_impl.insert(value)
    if isNewEntry {
      appendNode(ListHashSetNode(value))
    }
    return AddResult(isNewEntry: isNewEntry)
  }

  func last() -> T {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func find(value: T) -> ListHashSetIterator<T> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func makeIterator() -> iterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func appendNode(_ node: Node) {
    node.m_prev = m_tail
    node.m_next = nil

    if m_tail != nil {
      assert(m_head != nil)
      m_tail!.m_next = node
    } else {
      assert(m_head == nil)
      m_head = node
    }

    m_tail = node
  }

  private func makeIterator(_ position: Node?) -> iterator {
    return iterator(self, position)
  }

  private var m_impl = Set<T>()
  private var m_head: Node? = nil
  private var m_tail: Node? = nil
}

class ListHashSetNode<T> {
  init(_ value: T) { m_value = value }

  let m_value: T
  var m_prev: ListHashSetNode<T>? = nil
  var m_next: ListHashSetNode<T>? = nil
}
