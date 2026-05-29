/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2008, 2009, 2010 Apple Inc. All right reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2014 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

struct BidiIsolatedRun {
  let object: RenderObjectWrapper
  let root: RenderElementWrapper
  let runToReplace: BidiRun
  let position: UInt32
}

// This class is used to RenderInline subtrees, stepping by character within the
// text children. LegacyInlineIterator will use next to find the next RenderText
// optionally notifying a BidiResolver every time it steps into/out of a RenderInline.
class LegacyInlineIterator {
  init(root: RenderElementWrapper?, o: RenderObjectWrapper?, p: UInt32) {
    m_root = root
    m_renderer = o
    m_pos = p
    m_refersToEndOfPreviousNode = false
  }

  func renderer() -> RenderObjectWrapper? { return m_renderer }

  func increment(resolver: InlineBidiResolver? = nil) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func atEnd() -> Bool { return m_renderer == nil }

  func current() -> UChar { return characterAt(m_pos) }

  private func characterAt(_ index: UInt32) -> UChar {
    guard let textRenderer = m_renderer as? RenderTextWrapper else { return 0 }
    return textRenderer.characterAt(index)
  }

  private let m_root: RenderElementWrapper?
  private let m_renderer: RenderObjectWrapper?

  private let m_pos: UInt32

  // There are a couple places where we want to decrement an LegacyInlineIterator.
  // Usually this take the form of decrementing m_pos; however, m_pos might be 0.
  // However, we shouldn't ever need to decrement an LegacyInlineIterator more than
  // once, so rather than implementing a decrement() function which traverses
  // nodes, we can simply keep track of this state and handle it.
  private let m_refersToEndOfPreviousNode: Bool
}
