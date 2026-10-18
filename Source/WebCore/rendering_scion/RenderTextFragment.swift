/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007 Apple Inc. All rights reserved.
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

// Used to represent a text substring of an element, e.g., for text runs that are split because of
// first letter and that must therefore have different styles (and positions in the render tree).
// We cache offsets so that text transformations can be applied in such a way that we can recover
// the original unaltered string from our corresponding DOM node.
final class RenderTextFragmentWrapper: RenderTextWrapper {
  init(textNode: TextWrapper, text: StringWrapper, startOffset: Int32, length: Int32) {
    m_start = UInt32(startOffset)
    m_end = UInt32(length)
    super.init(
      .TextFragment, textNode,
      text.substring(position: UInt32(startOffset), length: UInt32(length)))
  }

  init(document: Document, text: StringWrapper, startOffset: Int32, length: Int32) {
    m_start = UInt32(startOffset)
    m_end = UInt32(length)
    super.init(
      .TextFragment, document.ContainerNode(),
      text.substring(position: UInt32(startOffset), length: UInt32(length)))
  }

  init(document: Document, text: StringWrapper) {
    m_start = 0
    m_end = text.length()
    m_contentString = text
    super.init(.TextFragment, document.ContainerNode(), text)
  }

  override init(p: UnsafeMutableRawPointer) {
    m_start = 0
    m_end = 0
    super.init(p: p)
  }

  override func canBeSelectionLeaf() -> Bool {
    assert(isNativeImpl())
    return textNode()?.hasEditableStyle() ?? false
  }

  func start() -> UInt32 {
    assert(isNativeImpl())
    return m_start
  }

  func firstLetter() -> RenderBoxModelObjectWrapper? {
    assert(isNativeImpl())
    return m_firstLetter
  }

  func setFirstLetter(firstLetter: RenderBoxModelObjectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func blockForAccompanyingFirstLetter() -> RenderBlockWrapper? {
    if m_firstLetter == nil {
      return nil
    }
    for block: RenderBlockWrapper in ancestorsOfType(descendant: m_firstLetter!) {
      if block is RenderMultiColumnFlowWrapper {
        break
      }
      if block.style().hasPseudoStyle(pseudo: .FirstLetter) && block.canHaveChildren() {
        return block
      }
    }
    return nil
  }

  func setAltText(_ altText: StringWrapper) {
    assert(isNativeImpl())
    m_altText = altText
  }

  func contentString() -> StringWrapper? {
    assert(isNativeImpl())
    return m_contentString
  }

  func setContentString(text: StringWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func setTextInternal(_ newText: StringWrapper, _ force: Bool) {
    assert(isNativeImpl())
    super.setTextInternal(newText, force)

    m_start = 0
    m_end = text().length()
    if m_firstLetter == nil {
      return
    }
    // TODO(asuhan): destroy the first letter through the render tree builder
    fatalError("Not implemented")
  }

  override func previousCharacter() -> UChar {
    assert(isNativeImpl())
    if start() != 0 {
      let original = textNode()?.data() ?? contentString()
      if let original, !original.isNull() && start() <= original.length() {
        return original[start() - 1]
      }
    }

    return super.previousCharacter()
  }

  private var m_start: UInt32
  private var m_end: UInt32
  // Alternative description that can be used for accessibility instead of the native text.
  private var m_altText: StringWrapper? = nil
  private var m_contentString: StringWrapper? = nil
  private let m_firstLetter: RenderBoxModelObjectWrapper? = nil
}
