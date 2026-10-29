/*
 * Copyright (C) 2013-2023 Apple Inc. All rights reserved.
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

// Range for iterating a node's element ancestors.
class ElementAncestorRange<T: ElementWrapper>: Sequence, IteratorProtocol {
  init(first: T?) {
    m_first = first
    m_current = first
  }

  func makeIterator() -> ElementAncestorRange<T> {
    return ElementAncestorRange<T>(first: m_first)
  }

  func next() -> T? {
    guard let current = m_current else { return nil }
    m_current = findElementAncestorOfType(current)
    return current
  }

  func first() -> T? { return m_first }

  private let m_first: T?
  private var m_current: T?
}

func findElementAncestorOfType<ElementType: ElementWrapper>(_ node: NodeWrapper) -> ElementType? {
  var ancestor = node.parentElement()
  while let current = ancestor {
    if let element = current as? ElementType {
      return element
    }
    ancestor = current.parentElement()
  }
  return nil
}

func ancestorsOfType<ElementType: ElementWrapper>(descendant: NodeWrapper)
  -> ElementAncestorRange<ElementType>
{
  return ElementAncestorRange<ElementType>(first: findElementAncestorOfType(descendant))
}
