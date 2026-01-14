/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2022 Apple Inc. All rights reserved.
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

// TODO(asuhan): inherit from OverlapTestRequestClient as well
class RenderWidgetWrapper: RenderReplacedWrapper {
  func frameOwnerElement() -> HTMLFrameOwnerElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func widget() -> Widget? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func requiresAcceleratedCompositing() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func remoteFrame() -> RemoteFrameWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if !shouldPaint(&paintInfo, paintOffset) {
      return
    }

    if paintInfo.context().detectingContentfulPaint() {
      return
    }

    let adjustedPaintOffset = paintOffset + location()

    if hasVisibleBoxDecorations()
      && (paintInfo.phase == .Foreground || paintInfo.phase == .Selection)
    {
      paintBoxDecorations(paintInfo: paintInfo, paintOffset: adjustedPaintOffset)
    }

    if paintInfo.phase == .Mask {
      paintMask(paintInfo: paintInfo, paintOffset: adjustedPaintOffset)
      return
    }

    if (paintInfo.phase == .Outline || paintInfo.phase == .SelfOutline) && hasOutline() {
      paintOutline(
        paintInfo: paintInfo,
        paintRect: LayoutRectWrapper(location: adjustedPaintOffset, size: size()))
    }

    // FIXME: Shouldn't check if the frame view needs layout during event region painting. This is a workaround
    // for the fact that non-composited frames depend on their enclosing compositing layer to perform an event
    // region update on their behalf. See <https://webkit.org/b/210311> for more details.
    let frameView = m_widget as? LocalFrameViewWrapper
    let needsEventRegionContentPaint =
      paintInfo.phase == .EventRegion && frameView != nil && !frameView!.needsLayout()
    if paintInfo.phase != .Foreground && !needsEventRegionContentPaint {
      return
    }

    if style().hasBorderRadius() {
      let borderRect = LayoutRectWrapper(location: adjustedPaintOffset, size: size())

      if borderRect.isEmpty() {
        return
      }

      // Push a clip if we have a border radius, since we want to round the foreground content that gets painted.
      paintInfo.context().save()
      clipToContentBoxShape(
        paintInfo.context(), adjustedPaintOffset, document().deviceScaleFactor())
    }

    if m_widget != nil && !isSkippedContentRoot() {
      paintContents(paintInfo, paintOffset)
    }

    if style().hasBorderRadius() {
      paintInfo.context().restore()
    }

    if paintInfo.phase == .EventRegion || paintInfo.phase == .Accessibility {
      return
    }

    // Paint a partially transparent wash over selected widgets.
    if isSelected() && !document().printing() {
      var rect = localSelectionRect()
      rect.moveBy(offset: adjustedPaintOffset)
      paintInfo.context().fillRect(
        rect: FloatRectWrapper(r: snappedIntRect(rect: rect)), color: selectionBackgroundColor())
    }

    if hasLayer() && layer()!.canResize() {
      assert(layer()!.scrollableArea() != nil)
      layer()!.scrollableArea()!.paintResizer(
        context: paintInfo.context(),
        paintOffset: LayoutPointWrapper(point: roundedIntPoint(point: adjustedPaintOffset)),
        damageRect: paintInfo.rect)
    }
  }

  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func needsPreferredWidthsRecalculation() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func embeddedContentBox() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintContents(_ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let m_widget: Widget? = nil
}
