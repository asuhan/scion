/*
 * Copyright (C) Research In Motion Limited 2010-2012. All rights reserved.
 * Copyright (C) 2024 Apple Inc. All rights reserved.
 * Copyright (C) 2015 Google Inc. All rights reserved.
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

// SVGTextLayoutAttributesBuilder performs the first layout phase for SVG text.
//
// It extracts the x/y/dx/dy/rotate values from the SVGTextPositioningElements in the DOM.
// These values are propagated to the corresponding RenderSVGInlineText renderers.
// The first layout phase only extracts the relevant information needed in RenderBlockLineLayout
// to create the InlineBox tree based on text chunk boundaries & BiDi information.
// The second layout phase is carried out by SVGTextLayoutEngine.

struct SVGTextLayoutAttributesBuilder: ~Copyable {
  init() { self.textLength = 0 }

  @discardableResult
  mutating func buildLayoutAttributesForForSubtree(_ textRoot: RenderSVGTextWrapper) -> Bool {
    characterDataMap.removeAll()

    if textPositions.isEmpty {
      textLength = 0
      var lastCharacterWasSpace = true
      collectTextPositioningElements(textRoot, &lastCharacterWasSpace)
    }

    if textLength == 0 {
      return false
    }

    buildCharacterDataMap(textRoot)
    metricsBuilder.buildMetricsAndLayoutAttributes(textRoot, nil, &characterDataMap)
    return true
  }

  func buildLayoutAttributesForTextRenderer(_ text: RenderSVGInlineTextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rebuildMetricsForSubtree(_ text: RenderSVGTextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Invoked whenever the underlying DOM tree changes, so that m_textPositions is rebuild.
  func clearTextPositioningElements() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func numberOfTextPositioningElements() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private struct TextPosition {
    let element: SVGTextPositioningElementWrapper?
    let start: UInt32
    let length: UInt32
  }

  private func buildCharacterDataMap(_ textRoot: RenderSVGTextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func collectTextPositioningElements(
    _ start: RenderBoxModelObjectWrapper, _ lastCharacterWasSpace: inout Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var textLength: UInt32
  private var textPositions: [TextPosition] = []
  private var characterDataMap: SVGCharacterDataMap = [:]
  private let metricsBuilder = SVGTextMetricsBuilder()
}
