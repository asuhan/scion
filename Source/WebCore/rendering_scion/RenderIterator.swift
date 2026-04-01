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

class RenderIterator<T: RenderObjectWrapper>: Equatable {
  init(root: RenderElementWrapper?) {
    m_root = root
    m_current = nil
  }

  init(root: RenderElementWrapper?, current: T?) {
    m_root = root
    m_current = current
  }

  static prefix func * (this: RenderIterator<T>) -> T { return this.m_current! }

  func bool() -> Bool { return m_current != nil }

  static func == (this: RenderIterator, other: RenderIterator) -> Bool {
    assert(CPtrToInt(this.m_root?.id()) == CPtrToInt(other.m_root?.id()))
    return CPtrToInt(this.m_current?.id()) == CPtrToInt(other.m_current?.id())
  }

  func traverseNext() -> RenderIterator<T> {
    m_current = RenderTraversal.next(m_current!, m_root)
    return self
  }

  @discardableResult
  func traverseNextSibling() -> RenderIterator<T> {
    m_current = RenderTraversal.nextSibling(m_current!)
    return self
  }

  private let m_root: RenderElementWrapper?
  private var m_current: T?
}

class IsRendererOfType<T> {
  static func f<U>(_ renderer: U) -> Bool { return renderer is T }
}

class RenderObjectTraversal {
  private static func nextAncestorSibling(
    current: RenderObjectWrapper, stayWithin: RenderObjectWrapper?
  ) -> RenderObjectWrapper? {
    var ancestor = current.parent()
    while ancestor != nil {
      if CPtrToInt(ancestor!.id()) == CPtrToInt(stayWithin?.id()) {
        return nil
      }
      if let sibling = ancestor!.nextSibling() {
        return sibling
      }
      ancestor = ancestor!.parent()
    }
    return nil
  }

  static func next<U: RenderObjectWrapper>(_ current: U, _ stayWithin: RenderObjectWrapper?)
    -> RenderObjectWrapper?
  {
    if let child = firstChild(current) {
      return child
    }

    if CPtrToInt(current.id()) == CPtrToInt(stayWithin?.id()) {
      return nil
    }

    if let sibling = current.nextSibling() {
      return sibling
    }

    return nextAncestorSibling(current: current, stayWithin: stayWithin)
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

  static func next<T, U: RenderObjectWrapper>(_ current: U, _ stayWithin: RenderObjectWrapper?)
    -> T?
  {
    var descendant = RenderObjectTraversal.next(current, stayWithin)
    while descendant != nil && !IsRendererOfType<T>.f(descendant!) {
      descendant = RenderObjectTraversal.next(descendant!, stayWithin)
    }
    return descendant as! T?
  }
}
