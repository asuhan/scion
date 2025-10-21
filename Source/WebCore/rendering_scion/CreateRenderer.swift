/*
 * Copyright (C) 2025 Scion authors. All rights reserved.
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

class CreateRenderer {
  static func RenderInline(
    type: RenderObjectWrapper.`Type`, element: ElementWrapper, style: RenderStyleWrapper
  )
    -> RenderInlineWrapper
  {
    return RenderInlineWrapper(type: type, element: element, style: style)
  }

  static func RenderInline(
    type: RenderObjectWrapper.`Type`, document: Document, style: RenderStyleWrapper
  )
    -> RenderInlineWrapper
  {
    return RenderInlineWrapper(type: type, document: document, style: style)
  }

  static func RenderBlockFlow(
    type: RenderObjectWrapper.`Type`, document: Document, style: RenderStyleWrapper,
    flags: RenderObjectWrapper.BlockFlowFlag = []
  ) -> RenderBlockFlowWrapper {
    return RenderBlockFlowWrapper(type: type, document: document, style: style, flags: flags)
  }

  static func RenderTextFragment(
    textNode: TextWrapper, text: StringWrapper, startOffset: Int32, length: Int32
  ) -> RenderTextFragmentWrapper {
    return RenderTextFragmentWrapper(
      textNode: textNode, text: text, startOffset: startOffset, length: length)
  }

  static func RenderTextFragment(
    document: Document, text: StringWrapper, startOffset: Int32, length: Int32
  ) -> RenderTextFragmentWrapper {
    return RenderTextFragmentWrapper(
      document: document, text: text, startOffset: startOffset, length: length)
  }
}
