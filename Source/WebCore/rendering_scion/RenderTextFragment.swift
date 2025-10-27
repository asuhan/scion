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
  convenience init(textNode: TextWrapper, text: StringWrapper, startOffset: Int32, length: Int32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  convenience init(document: Document, text: StringWrapper, startOffset: Int32, length: Int32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  convenience init(document: Document, text: StringWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFirstLetter(firstLetter: RenderBoxModelObjectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func blockForAccompanyingFirstLetter() -> RenderBlockWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setContentString(text: StringWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
