/*
 * Copyright (C) Research In Motion Limited 2010-2012. All rights reserved.
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
 */

struct MeasureTextData {
  let allCharactersMap: SVGTextLayoutAttributesBuilder.SVGCharacterDataMapRef
  var processRenderer = false
}

struct SVGTextMetricsBuilder {
  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func buildMetricsAndLayoutAttributes(
    _ textRoot: RenderSVGTextWrapper, _ stopAtLeaf: RenderSVGInlineTextWrapper?,
    _ allCharactersMap: SVGTextLayoutAttributesBuilder.SVGCharacterDataMapRef
  ) {
    let data = MeasureTextData(allCharactersMap: allCharactersMap)
    walkTree(textRoot, stopAtLeaf, data)
  }

  private func walkTree(
    _ start: RenderElementWrapper, _ stopAtLeaf: RenderSVGInlineTextWrapper?,
    _ data: MeasureTextData
  ) {
    var valueListPosition: UInt32 = 0
    var lastCharacter: UChar = 0
    var child = start.firstChild()
    while child != nil {
      if let text = child as? RenderSVGInlineTextWrapper {
        var data = data
        data.processRenderer = stopAtLeaf == nil || CPtrToInt(stopAtLeaf!.p) == CPtrToInt(text.p)
        (valueListPosition, lastCharacter) = measureTextRenderer(
          text, data, (valueListPosition, lastCharacter))
        if stopAtLeaf != nil && CPtrToInt(stopAtLeaf!.p) == CPtrToInt(text.p) {
          return
        }
      } else if let renderer = child as? RenderSVGInlineWrapper,
        let inlineChild = renderer.firstChild()
      {
        // Visit children of text content elements.
        child = inlineChild
        continue
      }
      child = child!.nextInPreOrderAfterChildren(start)
    }
  }

  private func measureTextRenderer(
    _ text: RenderSVGInlineTextWrapper, _ data: MeasureTextData, _ state: (UInt32, UChar)
  ) -> (UInt32, UChar) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
