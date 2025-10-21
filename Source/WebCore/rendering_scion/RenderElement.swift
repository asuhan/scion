/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2022 Apple Inc. All rights reserved.
 * Copyright (C) 2010, 2012 Google Inc. All rights reserved.
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

import wk_interop

class RenderElementWrapper: RenderObjectWrapper {
  func initializeStyle() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Calling with minimalStyleDifference > StyleDifference::Equal indicates that
  // out-of-band state (e.g. animations) requires that styleDidChange processing
  // continue even if the style isn't different from the current style.
  func setStyle(style: RenderStyleWrapper, minimalStyleDifference: StyleDifference = .Equal) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The pseudo element style can be cached or uncached. Use the uncached method if the pseudo element
  // has the concept of changing state (like ::-webkit-scrollbar-thumb:hover), or if it takes additional
  // parameters (like ::highlight(name)).
  func getCachedPseudoStyle(
    pseudoElementIdentifier: Style.PseudoElementIdentifier, parentStyle: RenderStyleWrapper? = nil
  ) -> RenderStyleWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func getUncachedPseudoStyle(
    pseudoElementRequest: Style.PseudoElementRequest, parentStyle: RenderStyleWrapper? = nil,
    ownStyle: RenderStyleWrapper? = nil
  )
    -> RenderStyleWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func element() -> ElementWrapper? {
    if let elementRaw = wk_interop.RenderElement_element(p) {
      return ElementWrapper(p: elementRaw)
    }
    return nil
  }

  func firstChild() -> RenderObjectWrapper? {
    if let childRaw = wk_interop.RenderElement_firstChild(p) {
      return RenderObjectWrapper(p: childRaw)
    }
    return nil
  }

  func lastChild() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layoutBox() -> ElementBoxWrapper? {
    return super.layoutBox() as? ElementBoxWrapper
  }

  // Note that even if these 2 "canContain" functions return true for a particular renderer, it does not necessarily mean the renderer is the containing block (see containingBlockForAbsolute(Fixed)Position).
  func canContainFixedPositionObjects() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func canContainAbsolutelyPositionedObjects() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldApplyPaintContainment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldApplyLayoutOrPaintContainment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Obtains the selection colors that should be used when painting a selection.
  func selectionBackgroundColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func selectionForegroundColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isChildAllowed(child: RenderObjectWrapper, style: RenderStyleWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func didAttachChild(child: RenderObjectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setChildNeedsLayout(markParents: MarkingBehavior = .MarkContainingBlockChain) {
    wk_interop.RenderElement_setChildNeedsLayout(p, markParents.rawValue)
  }

  func setOutOfFlowChildNeedsStaticPositionLayout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsSimplifiedNormalFlowLayout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // paintOffset is the offset from the origin of the GraphicsContext at which to paint the current object.
  func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    fatalError("Not reached")
  }

  // inline-block elements paint all phases atomically. This function ensures that. Certain other elements
  // (grid items, flex items) require this behavior as well, and this function exists as a helper for them.
  // It is expected that the caller will call this function independent of the value of paintInfo.phase.
  func paintAsInlineBlock(paintInfo: PaintInfoWrapper, childPoint: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  /* This function performs a layout only if one is needed. */
  func layoutIfNeeded() {
    wk_interop.RenderElement_layoutIfNeeded(p)
  }

  // Returns true if this renderer requires a new stacking context.
  static func createsGroupForStyle(style: RenderStyleWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isTransparent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func opacity() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func visibleToHitTesting(request: HitTestRequestWrapper? = nil) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBackground() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasMask() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasClip() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasClipOrNonVisibleOverflow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasClipPath() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func requiresRenderingConsolidationForViewTransition() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOutline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasSelfPaintingLayer() -> Bool {
    return wk_interop.RenderElement_hasSelfPaintingLayer(p)
  }

  func checkForRepaintDuringLayout() -> Bool {
    return wk_interop.RenderElement_checkForRepaintDuringLayout(p)
  }

  func hasFilter() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBackdropFilter() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBlendMode() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isContinuation() -> Bool {
    return wk_interop.RenderElement_isContinuation(p)
  }

  func setIsContinuation() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsFirstLetter() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func attachRendererInternal(child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?)
    -> RenderObjectWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func detachRendererInternal(renderer: RenderObjectWrapper) -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // https://www.w3.org/TR/css-transforms-1/#transform-box
  func transformReferenceBoxRect(style: RenderStyleWrapper) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // https://www.w3.org/TR/css-transforms-1/#reference-box
  func referenceBoxRect(boxType: CSSBoxType) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func backdropRenderer() -> RenderBlockFlowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isWritingModeRoot() -> Bool {
    return wk_interop.RenderElement_isWritingModeRoot(p)
  }

  func paintRectToClipOutFromBorder(paintRect: LayoutRectWrapper) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSkippedContentRoot() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintOutline(paintInfo: PaintInfoWrapper, paintRect: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
