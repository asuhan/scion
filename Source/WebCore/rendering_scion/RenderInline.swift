/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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

class RenderInlineWrapper: RenderBoxModelObjectWrapper {
  override init(p: UnsafeMutableRawPointer?) {
    if p != nil {
      super.init(p: p!)
    } else {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  init(type: `Type`, element: ElementWrapper, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(type: `Type`, document: Document, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func marginBefore(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func marginAfter(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func innerPaddingBoxWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func innerPaddingBoxHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func linesVisualOverflowBoundingBox() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintOutline(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
