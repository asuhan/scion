/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 *           (C) 2004 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2003-2022 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

class RenderObjectWrapper: CachedImageClientWrapper {
  init(p: UnsafeMutableRawPointer) {
    self.p = p
  }

  func layoutBox() -> BoxWrapper? {
    let unwrapped = wk_interop.RenderObject_layoutBox(p)
    if unwrapped == nil {
      return nil
    }
    let styleUnwrapped = wk_interop.Box_style(unwrapped)!
    let style = convert_render_style(p: styleUnwrapped)
    if wk_interop.Box_isInlineTextBox(unwrapped) {
      let box = convert_inline_text_box(p: unwrapped!)
      box.p = UnsafeRawPointer(unwrapped!)
      return box
    }
    if wk_interop.Box_isInitialContainingBlock(unwrapped) {
      let box = InitialContainingBlock(style: style)
      box.p = UnsafeRawPointer(unwrapped!)
      return box
    }
    if wk_interop.Box_isElementBox(unwrapped) {
      let box = ElementBoxWrapper(style: style)
      box.p = UnsafeRawPointer(unwrapped!)
      return box
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func theme() -> RenderTheme {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func parent() -> RenderElementWrapper? {
    let unwrapped = wk_interop.RenderObject_parent(p)
    if unwrapped == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return RenderElementWrapper(p: unwrapped!)
  }

  func previousSibling() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextSibling() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func enclosingLayer() -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func enclosingBoxModelObject() -> RenderBoxModelObjectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFieldset() -> Bool {
    return wk_interop.RenderObject_isFieldset(p)
  }

  func isRenderFrameSet() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isImage() -> Bool {
    return wk_interop.RenderObject_isImage(p)
  }

  func isRenderTextControl() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isDocumentElementRenderer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func everHadLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func childrenInline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGBlock() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isLegacyRenderSVGRoot() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isAnonymous() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isAnonymousBlock() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFloating() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isOutOfFlowPositioned() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isReplacedOrInlineBlock() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isHorizontalWritingMode() -> Bool {
    return wk_interop.RenderObject_isHorizontalWritingMode(p)
  }

  func isExcludedFromNormalLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isExcludedAndPlacedInBorder() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasVisibleBoxDecorations() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func backgroundIsKnownToBeObscured(paintOffset: LayoutPointWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasNonVisibleOverflow() -> Bool {
    return wk_interop.RenderObject_hasNonVisibleOverflow(p)
  }

  func isTransformed() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func view() -> RenderViewWrapper {
    return RenderViewWrapper(p: wk_interop.RenderObject_view(p))
  }

  func node() -> NodeWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func document() -> Document {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func frame() -> LocalFrameWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func page() -> PageWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func settings() -> SettingsWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func minPreferredLogicalWidth() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderObject_minPreferredLogicalWidth(p))
  }

  func maxPreferredLogicalWidth() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderObject_maxPreferredLogicalWidth(p))
  }

  func setNeedsLayout(markParents: MarkingBehavior = .MarkContainingBlockChain) {
    wk_interop.RenderObject_setNeedsLayout(p, markParents.rawValue)
  }

  func hitTest(
    request: HitTestRequestWrapper, result: HitTestResultWrapper,
    locationInContainer: HitTestLocationWrapper, accumulatedOffset: LayoutPointWrapper,
    hitTestFilter: HitTestFilter = .HitTestAll
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func protectedNodeForHitTest() -> NodeWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateHitTestResult(result: HitTestResultWrapper, point: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func containingBlock() -> RenderBlockWrapper? {
    if let unwrapped = wk_interop.RenderObject_containingBlock(p) {
      // TODO(asuhan): decide the type correctly
      if wk_interop.RenderObject_isRenderListItem(unwrapped) {
        return RenderListItemWrapper(p: unwrapped)
      }
      return RenderBlockWrapper(p: unwrapped)
    }
    return nil
  }

  static func containingBlockForPositionType(
    positionType: PositionType, renderer: RenderObjectWrapper
  )
    -> RenderBlockWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Convert the given local point to absolute coordinates. If OptionSet<MapCoordinatesMode> includes UseTransforms, take transforms into account.
  func localToAbsolute(
    localPoint: FloatPoint = FloatPoint(), mode: MapCoordinatesMode = MapCoordinatesMode(),
    wasFixed: Bool? = nil
  ) -> FloatPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func style() -> RenderStyleWrapper {
    return convert_render_style(p: wk_interop.RenderObject_style(p))
  }

  func firstLineStyle() -> RenderStyleWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Repaint the entire object.  Called when, e.g., the color of a border changes, or when a border
  // style changes.
  enum ForceRepaint {
    case No
    case Yes
  }

  func repaint(forceRepaint: ForceRepaint = .No) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInFlow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum HighlightState: UInt8 {
    case None  // The object is not selected.
    case Start  // The object either contains the start of a selection run or is the start of a run
    case Inside  // The object is fully encompassed by a selection run
    case End  // The object either contains the end of a selection run or is the end of a run
    case Both  // The object contains an entire run or is the sole selected object in that run
  }

  static func createFromRawPointer(p: UnsafeMutableRawPointer) -> RenderObjectWrapper {
    if wk_interop.RenderObject_isRenderListBox(p) {
      return RenderListBoxWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderListItem(p) {
      return RenderListItemWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderBlockFlow(p) {
      return RenderBlockFlowWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderFlexibleBox(p) {
      return RenderFlexibleBoxWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderBlock(p) {
      return RenderBlockWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderListMarker(p) {
      return RenderListMarkerWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderBox(p) {
      return RenderBoxWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderText(p) {
      return RenderTextWrapper(p: p)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var p: UnsafeMutableRawPointer
}
