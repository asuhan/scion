/*
 * Copyright (C) 2013 Apple Inc. All rights reserved.
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

class RenderChildIterator<T: RenderObjectWrapper>: RenderIterator<T> {
  init(_ parent: RenderElementWrapper) { super.init(root: parent) }
  init(_ parent: RenderElementWrapper, _ current: T?) { super.init(root: parent, current: current) }

  func next() -> T? {
    let result = bool() ? *self : nil
    super.traverseNextSibling()
    return result
  }
}

class RenderChildIteratorAdapter<T: RenderObjectWrapper>: Sequence, IteratorProtocol {
  init(_ parent: RenderElementWrapper) {
    m_parent = parent
    begin = RenderChildIterator(parent, RenderTraversal.firstChild(parent))
    end = RenderChildIterator(parent)
    current = begin
  }

  func makeIterator() -> RenderChildIteratorAdapter<T> {
    return RenderChildIteratorAdapter<T>(m_parent)
  }

  func next() -> T? {
    if current == end {
      return nil
    }
    let result = *current
    current = current.traverseNextSibling() as! RenderChildIterator<T>
    return result
  }

  func first() -> T? {
    let firstChild: T? = RenderTraversal.firstChild(m_parent)
    return firstChild
  }

  private let m_parent: RenderElementWrapper
  private let begin: RenderChildIterator<T>
  private let end: RenderChildIterator<T>
  private var current: RenderChildIterator<T>
}

func childrenOfType<T>(parent: RenderElementWrapper) -> RenderChildIteratorAdapter<T> {
  return RenderChildIteratorAdapter<T>(parent)
}
