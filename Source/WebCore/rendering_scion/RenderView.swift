/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2006, 2015-2016 Apple Inc.
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

import wk_interop

class RenderViewWrapper: RenderBlockFlowWrapper {
  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func frameView() -> LocalFrameViewWrapper {
    return LocalFrameViewWrapper(p: wk_interop.RenderView_frameView(p))
  }

  func layoutState() -> LayoutStateWrapper {
    return LayoutStateWrapper(p: wk_interop.RenderView_layoutState(p))
  }

  func needsEventRegionUpdateForNonCompositedFrame() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func repaintRootContents() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func selection() -> RenderSelection {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func printing() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pageOrViewLogicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setBestTruncatedAt(
    y: Int32, forRenderer: RenderBoxModelObjectWrapper, forcedBreak: Bool = false
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func truncatedAt() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func printRect() -> IntRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func unscaledDocumentRect() -> IntRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rootElementShouldPaintBaseBackground() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasQuotesNeedingUpdate() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasRenderersWithOutline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func viewTransitionRoot() -> RenderElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setViewTransitionRoot(renderer: RenderElementWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func requiresColumns(desiredColumnCount: Int32) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
