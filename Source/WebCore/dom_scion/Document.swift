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

  func isImageDocument() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSVGDocument() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isPluginDocument() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasSVGRootNode() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fontSelector() -> CSSFontSelectorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func protectedFontSelector() -> CSSFontSelectorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func view() -> LocalFrameViewWrapper? {
    return LocalFrameViewWrapper(p: wk_interop.Document_view(p))
  }

  func page() -> PageWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func settings() -> SettingsWrapper {
    return SettingsWrapper(wk_interop.Document_settings(p))
  }

  func deviceScaleFactor() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func compositeOperatorForBackgroundColor(color: ColorWrapper, renderer: RenderObjectWrapper)
    -> CompositeOperator
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func renderView() -> RenderViewWrapper? {
    let raw = wk_interop.Document_renderView(p)
    return raw != nil ? RenderViewWrapper(p: raw!) : nil
  }

  func existingAXObjectCache() -> AXObjectCacheWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func axObjectCache() -> AXObjectCacheWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func printing() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paginated() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inQuirksMode() -> Bool {
    return wk_interop.Document_inQuirksMode(p)
  }

  func inLimitedQuirksMode() -> Bool {
    return wk_interop.Document_inLimitedQuirksMode(p)
  }

  func inNoQuirksMode() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func focusedElement() -> ElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns the owning element in the parent document.
  // Returns nullptr if this is the top level document.
  func ownerElement() -> HTMLFrameOwnerElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func markersIfExists() -> DocumentMarkerControllerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func topDocument() -> Document { return Document(wk_interop.Document_topDocument(p)) }

  enum BackForwardCacheState {
    case NotInBackForwardCache
    case AboutToEnterBackForwardCache
    case InBackForwardCache
  }

  func backForwardCacheState() -> BackForwardCacheState {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func displayStringModifiedByEncoding(_ string: StringWrapper) -> StringWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func invalidateRenderingDependentRegions() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func visualUpdatesAllowed() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inRenderTreeUpdate() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func topLayerElements() -> ListSet<ElementWrapper, ElementWrapper> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasTopLayerElement() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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

  func hasHighlight() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func ContainerNode() -> ContainerNodeWrapper { return ContainerNodeWrapper(p: p) }

  private let p: UnsafeMutableRawPointer
}
