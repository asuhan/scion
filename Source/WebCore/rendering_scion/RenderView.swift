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

import Foundation
import wk_interop

class RenderViewWrapper: RenderBlockFlowWrapper {
  override func layout() {
    // TODO(asuhan): add stack stats
    if !document().paginated() {
      pageLogicalSize = nil
    }

    if shouldUsePrintingLayout() {
      if pageLogicalSize == nil {
        pageLogicalSize = LayoutSizeWrapper(
          width: logicalWidth(), height: LayoutUnit(value: UInt64(0)))
      }
      minPreferredLogicalWidth = pageLogicalSize!.width()
      maxPreferredLogicalWidth = minPreferredLogicalWidth
    }

    // Use calcWidth/Height to get the new width/height, since this will take the full page zoom factor into account.
    let relayoutChildren =
      !shouldUsePrintingLayout() && (width() != viewWidth() || height() != viewHeight())
    if relayoutChildren {
      setChildNeedsLayout(markParents: .MarkOnlyThis)

      for box: RenderBoxWrapper in childrenOfType(parent: self) {
        if box.hasRelativeLogicalHeight()
          || box.style().logicalHeight().isPercentOrCalculated()
          || box.style().logicalMinHeight().isPercentOrCalculated()
          || box.style().logicalMaxHeight().isPercentOrCalculated()
          || box.isRenderOrLegacyRenderSVGRoot()
        {
          box.setChildNeedsLayout(markParents: .MarkOnlyThis)
        }
      }
    }

    assert(frameView().layoutContext().layoutState() == nil)
    if !needsLayout() {
      return
    }

    let _ = LayoutStateMaintainer(
      root: self, offset: LayoutSizeWrapper(), disablePaintOffsetCache: false,
      pageHeight: (pageLogicalSize ?? LayoutSizeWrapper()).height(),
      pageHeightChanged: pageLogicalHeightChanged)

    pageLogicalHeightChanged = false

    // FIXME: This should be called only when frame view (or the canvas we render onto) size changes.
    updateInitialContainingBlockSize()
    super.layout()

    #if !NDEBUG
      frameView().layoutContext().checkLayoutState()
    #endif
  }

  override func updateLogicalWidth() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func availableLogicalHeight(heightType: AvailableLogicalHeightType) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The same as the FrameView's layoutHeight/layoutWidth but with null check guards.
  private func viewHeight() -> Int32 {
    var height: Int32 = 0
    if !shouldUsePrintingLayout() {
      let frameView = frameView()
      height = frameView.layoutHeight()
      height = Int32(
        frameView.useFixedLayout() ? ceilf(style().usedZoom() * Float32(height)) : Float32(height))
    }
    return height
  }

  private func viewWidth() -> Int32 {
    var width: Int32 = 0
    if !shouldUsePrintingLayout() {
      let frameView = frameView()
      width = frameView.layoutWidth()
      width = Int32(
        frameView.useFixedLayout() ? ceilf(style().usedZoom() * Float32(width)) : Float32(width))
    }
    return width
  }

  func clientLogicalWidthForFixedPosition() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clientLogicalHeightForFixedPosition() -> LayoutUnit {
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

  // Return the renderer whose background style is used to paint the root background.
  func rendererForRootBackground() -> RenderElementWrapper? {
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

  func backgroundRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rootElementShouldPaintBaseBackground() -> Bool {
    let documentElement = document().documentElement()
    if let rootRenderer = documentElement != nil ? documentElement!.renderer() : nil {
      // The document element's renderer is currently forced to be a block, but may not always be.
      if let rootBox = rootRenderer as? RenderBoxWrapper, rootBox.hasLayer() {
        let layer = rootBox.layer()!
        if layer.isolatesBlending() || layer.isBackdropRoot() {
          return false
        }
      }
    }
    return shouldPaintBaseBackground()
  }

  private func shouldPaintBaseBackground() -> Bool {
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

  override func computeColumnCountAndWidth() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateInitialContainingBlockSize() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func shouldUsePrintingLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var pageLogicalSize: LayoutSizeWrapper? = nil
  private var pageLogicalHeightChanged = false
}
