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

  static func RenderTextFragment(document: Document, text: StringWrapper)
    -> RenderTextFragmentWrapper
  {
    return RenderTextFragmentWrapper(document: document, text: text)
  }

  static func RenderMultiColumnFlow(document: Document, style: RenderStyleWrapper)
    -> RenderMultiColumnFlowWrapper
  {
    return RenderMultiColumnFlowWrapper(document: document, style: style)
  }

  static func RenderMultiColumnSet(
    fragmentedFlow: RenderFragmentedFlowWrapper, style: RenderStyleWrapper
  ) -> RenderMultiColumnSetWrapper {
    return RenderMultiColumnSetWrapper(fragmentedFlow: fragmentedFlow, style: style)
  }

  static func RenderTableCol(document: Document, style: RenderStyleWrapper) -> RenderTableColWrapper
  {
    return RenderTableColWrapper(document: document, style: style)
  }

  static func RenderListMarker(listItem: RenderListItemWrapper, style: RenderStyleWrapper)
    -> RenderListMarkerWrapper
  {
    return RenderListMarkerWrapper(listItem: listItem, style: style)
  }

  static func RenderSVGViewportContainer(parent: RenderSVGRootWrapper, style: RenderStyleWrapper)
    -> RenderSVGViewportContainerWrapper
  {
    return RenderSVGViewportContainerWrapper(parent: parent, style: style)
  }

  static func RenderText(
    type: RenderObjectWrapper.`Type`, textNode: TextWrapper, text: StringWrapper
  )
    -> RenderTextWrapper
  {
    return RenderTextWrapper(type: type, textNode: textNode, text: text)
  }

  static func RenderText(type: RenderObjectWrapper.`Type`, document: Document, text: StringWrapper)
    -> RenderTextWrapper
  {
    return RenderTextWrapper(type: type, document: document, text: text)
  }

  static func RenderViewTransitionCapture(
    type: RenderObjectWrapper.`Type`, document: Document, style: RenderStyleWrapper
  ) -> RenderViewTransitionCaptureWrapper {
    return RenderViewTransitionCaptureWrapper(type: type, document: document, style: style)
  }

  static func RenderFlexibleBox(
    type: RenderObjectWrapper.`Type`, document: Document, style: RenderStyleWrapper
  ) -> RenderFlexibleBoxWrapper {
    return RenderFlexibleBoxWrapper(type: type, document: document, style: style)
  }

  static func RenderScrollbarPart(
    _ document: Document, _ style: RenderStyleWrapper, _ scrollbar: RenderScrollbar? = nil,
    _ part: ScrollbarPart = .NoPart
  ) -> RenderScrollbarPartWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
