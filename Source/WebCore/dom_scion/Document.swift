/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2004-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

// TODO(asuhan): inherit from all bases
class Document: TreeScopeWrapper {
  init(_ p: UnsafeMutableRawPointer) { self.p = p }

  func frame() -> LocalFrameWrapper? {
    let raw = wk_interop.Document_frame(p)
    return raw != nil ? LocalFrameWrapper(raw!) : nil
  }

  func documentElement() -> ElementWrapper? {
    let raw = wk_interop.Document_documentElement(p)
    return raw != nil ? ElementWrapper(p: raw!) : nil
  }

  func isImageDocument() -> Bool { return wk_interop.Document_isImageDocument(p) }

  func isSVGDocument() -> Bool { return wk_interop.Document_isSVGDocument(p) }

  func isPluginDocument() -> Bool { return wk_interop.Document_isPluginDocument(p) }

  func hasSVGRootNode() -> Bool { return wk_interop.Document_hasSVGRootNode(p) }

  func fontSelector() -> CSSFontSelectorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func protectedFontSelector() -> CSSFontSelectorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func view() -> LocalFrameViewWrapper? {
    return LocalFrameViewWrapper(wk_interop.Document_view(p))
  }

  func page() -> PageWrapper? { return PageWrapper(wk_interop.Document_page(p)) }

  func settings() -> SettingsWrapper {
    return SettingsWrapper(wk_interop.Document_settings(p))
  }

  func deviceScaleFactor() -> Float32 { return wk_interop.Document_deviceScaleFactor(p) }

  func useDarkAppearance(_ style: RenderStyleWrapper?) -> Bool {
    return wk_interop.Document_useDarkAppearance(p, style?.p!)
  }

  func compositeOperatorForBackgroundColor(color: ColorWrapper, renderer: RenderObjectWrapper)
    -> CompositeOperator
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func renderView() -> RenderViewWrapper? {
    guard let raw = wk_interop.Document_renderView(p) else { return nil }
    guard let viewRaw = RenderView_scion(raw) else { return nil }
    return Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  }

  func renderTreeBeingDestroyed() -> Bool { return wk_interop.Document_renderTreeBeingDestroyed(p) }

  func existingAXObjectCache() -> AXObjectCacheWrapper? {
    if wk_interop.Document_existingAXObjectCache(p) == nil {
      return nil
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func axObjectCache() -> AXObjectCacheWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func printing() -> Bool { return wk_interop.Document_printing(p) }

  func paginated() -> Bool { return wk_interop.Document_paginated(p) }

  func inQuirksMode() -> Bool {
    return wk_interop.Document_inQuirksMode(p)
  }

  func inLimitedQuirksMode() -> Bool {
    return wk_interop.Document_inLimitedQuirksMode(p)
  }

  func inNoQuirksMode() -> Bool { return wk_interop.Document_inNoQuirksMode(p) }

  func focusedElement() -> ElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns the owning element in the parent document.
  // Returns nullptr if this is the top level document.
  func ownerElement() -> HTMLFrameOwnerElementWrapper? {
    guard let raw = wk_interop.Document_ownerElement(p) else { return nil }
    return HTMLFrameOwnerElementWrapper(p: raw)
  }

  // This is the "HTML body element" as defined by CSSOM View spec, the first body child of the
  // document element. See http://dev.w3.org/csswg/cssom-view/#the-html-body-element.
  func body() -> HTMLBodyElement? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // This is the "body element" as defined by HTML5, the first body or frameset child of the
  // document element. See https://html.spec.whatwg.org/multipage/dom.html#the-body-element-2.
  func bodyOrFrameset() -> HTMLElementWrapper? {
    return createHTMLElementWrapper(wk_interop.Document_bodyOrFrameset(p))
  }

  func markersIfExists() -> DocumentMarkerControllerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func topDocument() -> Document { return Document(wk_interop.Document_topDocument(p)) }

  enum BackForwardCacheState: UInt8 {
    case NotInBackForwardCache
    case AboutToEnterBackForwardCache
    case InBackForwardCache
  }

  func backForwardCacheState() -> BackForwardCacheState {
    return BackForwardCacheState(rawValue: wk_interop.Document_backForwardCacheState(p))!
  }

  func displayStringModifiedByEncoding(_ string: StringWrapper) -> StringWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func invalidateRenderingDependentRegions() {
    wk_interop.Document_invalidateRenderingDependentRegions(p)
  }

  func visualUpdatesAllowed() -> Bool { return wk_interop.Document_visualUpdatesAllowed(p) }

  func inRenderTreeUpdate() -> Bool { return wk_interop.Document_inRenderTreeUpdate(p) }

  func securityOrigin() -> SecurityOriginWrapper {
    return SecurityOriginWrapper(p: wk_interop.Document_securityOrigin(p))
  }

  func protectedSecurityOrigin() -> SecurityOriginWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func observeForContainIntrinsicSize(element: ElementWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func unobserveForContainIntrinsicSize(element: ElementWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func activeViewTransition() -> ViewTransitionWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func activeViewTransitionCapturedDocumentElement() -> Bool {
    return wk_interop.Document_activeViewTransitionCapturedDocumentElement(p)
  }

  func hasViewTransitionPseudoElementTree() -> Bool {
    return wk_interop.Document_hasViewTransitionPseudoElementTree(p)
  }

  func renderingIsSuppressedForViewTransition() -> Bool {
    return wk_interop.Document_renderingIsSuppressedForViewTransition(p)
  }

  func topLayerElements() -> ListHashSet<Ref<ElementWrapper>> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasTopLayerElement() -> Bool { return wk_interop.Document_hasTopLayerElement(p) }

  func hitTest(
    _ request: HitTestRequestWrapper, _ location: HitTestLocationWrapper,
    _ result: inout HitTestResultWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textManipulationControllerIfExists() -> TextManipulationControllerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasHighlight() -> Bool { return wk_interop.Document_hasHighlight(p) }

  func highlightRegistryIfExists() -> HighlightRegistryWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fragmentHighlightRegistryIfExists() -> HighlightRegistryWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func editor() -> EditorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // TODO(asuhan): move to ScriptExecutionContext
  func activeDOMObjectsAreSuspended() -> Bool {
    return wk_interop.Document_activeDOMObjectsAreSuspended(p)
  }

  func ContainerNode() -> ContainerNodeWrapper { return ContainerNodeWrapper(p: p) }

  let p: UnsafeMutableRawPointer
}
