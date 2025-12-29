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

// TODO(asuhan): inherit from all bases
class Document: TreeScopeWrapper {
  func documentElement() -> ElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isImageDocument() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func view() -> LocalFrameViewWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func settings() -> SettingsWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns the owning element in the parent document.
  // Returns nullptr if this is the top level document.
  func ownerElement() -> HTMLFrameOwnerElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func markersIfExists() -> DocumentMarkerControllerWrapper? {
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
}
