/*
 * Copyright (C) 1997 Martin Jones (mjones@kde.org)
 *           (C) 1997 Torben Weis (weis@kde.org)
 *           (C) 1998 Waldo Bastian (bastian@kde.org)
 *           (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2009, 2010, 2014 Apple Inc. All rights reserved.
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

enum SkipEmptySectionsValue {
  case DoNotSkipEmptySections
  case SkipEmptySections
}

class RenderTableWrapper: RenderBlockWrapper {
  // Per CSS 3 writing-mode: "The first and second values of the 'border-spacing' property represent spacing between columns
  // and rows respectively, not necessarily the horizontal and vertical spacing respectively".
  func hBorderSpacing() -> LayoutUnit { return hSpacing }

  func vBorderSpacing() -> LayoutUnit { return vSpacing }

  func collapseBorders() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderEnd() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderRight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderStart() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderEnd() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func forceSectionsRecalc() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct ColumnStruct {
    let span: Int32 = 1
  }

  func columnPositions() -> [LayoutUnit] { return columnPos }

  // This function returns nil if the table has no section.
  func topSection() -> RenderTableSectionWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func bottomSection() -> RenderTableSectionWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func numEffCols() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func colElement(col: UInt32) -> RenderTableColWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func sectionAbove(
    section: RenderTableSectionWrapper?,
    skipEmptySections: SkipEmptySectionsValue = .DoNotSkipEmptySections
  ) -> RenderTableSectionWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  typealias CollapsedBorderValues = [CollapsedBorderValue]

  func currentBorderValue() -> CollapsedBorderValue? { return currentBorder }

  static func createAnonymousWithParentRenderer(parent: RenderElementWrapper) -> RenderTableWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createAnonymousBoxWithSameTypeAs(renderer: RenderBoxWrapper) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func willInsertTableColumn(child: RenderTableColWrapper, beforeChild: RenderObjectWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func willInsertTableSection(child: RenderTableSectionWrapper, beforeChild: RenderObjectWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func avoidsFloats() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private final func paintObject(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    var paintPhase = paintInfo.phase
    if (paintPhase == .BlockBackground || paintPhase == .ChildBlockBackground)
      && hasVisibleBoxDecorations() && style().usedVisibility() == .Visible
    {
      paintBoxDecorations(paintInfo: paintInfo, paintOffset: paintOffset)
    }

    if paintPhase == .Mask {
      paintMask(paintInfo: paintInfo, paintOffset: paintOffset)
      return
    }

    if paintPhase == .Accessibility {
      paintInfo.accessibilityRegionContext()!.takeBounds(renderBox: self, paintOffset: paintOffset)
    }

    // We're done.  We don't bother painting any children.
    if paintPhase == .BlockBackground {
      return
    }

    // We don't paint our own background, but we do let the kids paint their backgrounds.
    if paintPhase == .ChildBlockBackgrounds {
      paintPhase = .ChildBlockBackground
    }

    var info = paintInfo
    info.phase = paintPhase
    info.updateSubtreePaintRootForChildren(renderer: self)

    for box: RenderBoxWrapper in childrenOfType(parent: self) {
      if !box.hasSelfPaintingLayer() && (box.isRenderTableSection() || box.isRenderTableCaption()) {
        let childPoint = flipForWritingModeForChild(child: box, point: paintOffset)
        box.paint(paintInfo: &info, paintOffset: childPoint)
      }
    }

    if collapseBorders() && paintPhase == .ChildBlockBackground
      && style().usedVisibility() == .Visible
    {
      recalcCollapsedBorders()
      // Using our cached sorted styles, we then do individual passes,
      // painting each style of border from lowest precedence to highest precedence.
      info.phase = .CollapsedTableBorders
      for collapsedBorder in collapsedBorders {
        currentBorder = collapsedBorder
        var section = bottomSection()
        while section != nil {
          let childPoint = flipForWritingModeForChild(child: section!, point: paintOffset)
          section!.paint(paintInfo: &info, paintOffset: childPoint)
          section = sectionAbove(section: section)
        }
      }
      currentBorder = nil
    }

    // Paint outline.
    if (paintPhase == .Outline || paintPhase == .SelfOutline) && hasOutline()
      && style().usedVisibility() == .Visible
    {
      paintOutline(
        paintInfo: paintInfo, paintRect: LayoutRectWrapper(location: paintOffset, size: size()))
    }
  }

  final override func paintBoxDecorations(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    if !paintInfo.shouldPaintWithinRoot(renderer: self) {
      return
    }

    var rect = LayoutRectWrapper(location: paintOffset, size: size())
    adjustBorderBoxRectForPainting(paintRect: &rect)

    let backgroundPainter = BackgroundPainter(renderer: self, paintInfo: paintInfo)

    let bleedAvoidance = determineBackgroundBleedAvoidance(context: paintInfo.context())
    if !BackgroundPainter.boxShadowShouldBeAppliedToBackground(
      renderer: self, paintOffset: rect.location(), bleedAvoidance: bleedAvoidance,
      inlineBox: InlineIterator.InlineBoxIterator())
    {
      backgroundPainter.paintBoxShadow(paintRect: rect, style: style(), shadowStyle: .Normal)
    }

    let stateSaver = GraphicsContextStateSaver(context: paintInfo.context(), saveAndRestore: false)
    if bleedAvoidance == .BackgroundBleedUseTransparencyLayer {
      // To avoid the background color bleeding out behind the border, we'll render background and border
      // into a transparency layer, and then clip that in one go (which requires setting up the clip before
      // beginning the layer).
      stateSaver.save()
      let borderShape = BorderShape.shapeForBorderRect(style: style(), borderRect: rect)
      borderShape.clipToOuterShape(
        context: paintInfo.context(), deviceScaleFactor: document().deviceScaleFactor())
      paintInfo.context().beginTransparencyLayer(opacity: 1)
    }

    backgroundPainter.paintBackground(paintRect: rect, bleedAvoidance: bleedAvoidance)
    backgroundPainter.paintBoxShadow(paintRect: rect, style: style(), shadowStyle: .Inset)

    if style().hasVisibleBorderDecoration() && !collapseBorders() {
      let borderPainter = BorderPainter(renderer: self, paintInfo: paintInfo)
      borderPainter.paintBorder(rect: rect, style: style())
    }

    if bleedAvoidance == .BackgroundBleedUseTransparencyLayer {
      paintInfo.context().endTransparencyLayer()
    }
  }

  final override func paintMask(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    if style().usedVisibility() != .Visible || paintInfo.phase != .Mask {
      return
    }

    var rect = LayoutRectWrapper(location: paintOffset, size: size())
    adjustBorderBoxRectForPainting(paintRect: &rect)

    paintMaskImages(paintInfo: paintInfo, paintRect: rect)
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeIntrinsicKeywordLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func updateLogicalWidth() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func adjustBorderBoxRectForPainting(paintRect: inout LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func recalcCollapsedBorders() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let columnPos: [LayoutUnit] = []
  let columns: [ColumnStruct] = []

  private let collapsedBorders = CollapsedBorderValues()
  private var currentBorder: CollapsedBorderValue? = nil

  private let hSpacing = LayoutUnit()
  private let vSpacing = LayoutUnit()
}
