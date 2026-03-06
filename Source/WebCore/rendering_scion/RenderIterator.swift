/*
 * Copyright (C) 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2024 Igalia S.L.
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

class RenderIterator<T: RenderObjectWrapper>: IteratorProtocol, Equatable {
  init(root: RenderElementWrapper?, current: T?) {
    m_root = root
    m_current = current
  }

  func next() -> T? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static prefix func * (this: RenderIterator<T>) -> T { return this.m_current! }

  func bool() -> Bool { return m_current != nil }

  static func == (this: RenderIterator, other: RenderIterator) -> Bool {
    assert(CPtrToInt(this.m_root?.p) == CPtrToInt(other.m_root?.p))
    return CPtrToInt(this.m_current?.p) == CPtrToInt(other.m_current?.p)
  }

  func traverseNext() -> RenderIterator<T> {
    m_current = RenderTraversal.next(m_current, m_root!)
    return self
  }

  func traverseNextSibling() -> RenderIterator<T> {
    m_current = RenderTraversal.nextSibling(m_current!)
    return self
  }

  private let m_root: RenderElementWrapper?
  private var m_current: T?
}

private class IsRendererOfType<T> {
  static func f<U>(_ renderer: U) -> Bool { return renderer is T }
}

class RenderObjectTraversal {
  static func next<U>(_ current: U, _ stayWithin: RenderObjectWrapper) -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func firstChild<U: RenderElementWrapper>(_ object: U) -> RenderObjectWrapper? {
    return object.firstChild()
  }

  static func firstChild(_ object: RenderObjectWrapper) -> RenderObjectWrapper? {
    return object.firstChildSlow()
  }

  static func firstChild(_ object: RenderTextWrapper) -> RenderObjectWrapper? {
    return nil
  }
}

class RenderTraversal {
  static func firstChild<T, U: RenderObjectWrapper>(_ current: U) -> T? {
    var object: RenderObjectWrapper? = RenderObjectTraversal.firstChild(current)
    while object != nil && !IsRendererOfType<T>.f(object!) {
      object = object!.nextSibling()
    }
    return object as! T?
  }

  static func nextSibling<T, U: RenderObjectWrapper>(_ current: U) -> T? {
    var object: RenderObjectWrapper? = current.nextSibling()
    while object != nil && !IsRendererOfType<T>.f(object!) {
      object = object!.nextSibling()
    }
    return object as! T?
  }

  static func next<T, U>(_ current: U, _ stayWithin: RenderObjectWrapper) -> T? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
