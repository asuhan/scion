/*
 * Copyright (C) 2006-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2019 Adobe. All rights reserved.
 * Copyright (C) 2014 Google. All rights reserved.
 * Copyright (C) 2020 Igalia S.L.
 *
 * Portions are Copyright (C) 1998 Netscape Communications Corporation.
 *
 * Other contributors:
 *   Robert O'Callahan <roc+@cs.cmu.edu>
 *   David Baron <dbaron@fas.harvard.edu>
 *   Christian Biesinger <cbiesinger@web.de>
 *   Randall Jesup <rjesup@wgate.com>
 *   Roland Mainz <roland.mainz@informatik.med.uni-giessen.de>
 *   Josh Soref <timeless@mac.com>
 *   Boris Zbarsky <bzbarsky@mit.edu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

final class RenderLayerScrollableArea: ScrollableAreaWrapper {
  init(layer: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clear() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func createOrDestroyMarquee() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func restoreScrollPosition() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollWidth() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollHeight() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasScrollableHorizontalOverflow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasScrollableVerticalOverflow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasScrollbars() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns true when the layer could do touch scrolling, but doesn't look at whether there is actually scrollable overflow.
  func canUseCompositedScrolling() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func verticalScrollbarWidth(
    relevancy: OverlayScrollbarSizeRelevancy = .IgnoreOverlayScrollbarSize,
    isHorizontalWritingMode: Bool = true
  ) -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func horizontalScrollbarHeight(
    relevancy: OverlayScrollbarSizeRelevancy = .IgnoreOverlayScrollbarSize,
    isHorizontalWritingMode: Bool = true
  ) -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintOverflowControls(
    context: GraphicsContextWrapper, paintOffset: IntPoint, damageRect: IntRect,
    paintingOverlayControls: Bool = false
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usesCompositedScrolling() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateScrollbarsAfterStyleChange(oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateAllScrollbarRelatedStyle() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeHasCompositedScrollableOverflow(layoutUpToDate: LayoutUpToDate) {
    var hasCompositedScrollableOverflow = m_hasCompositedScrollableOverflow

    switch layoutUpToDate {
    case .No:
      // If layout is not up to date, the only thing we can reliably know is that style prevents overflow scrolling.
      if !canUseCompositedScrolling() {
        hasCompositedScrollableOverflow = false
      }
    case .Yes:
      hasCompositedScrollableOverflow =
        canUseCompositedScrolling()
        && (hasScrollableHorizontalOverflow() || hasScrollableVerticalOverflow())
    }

    if hasCompositedScrollableOverflow == m_hasCompositedScrollableOverflow {
      return
    }

    // Whether this layer does composited scrolling affects the configuration of descendant sticky layers. We have to
    // dirty from the enclosing stacking context because overflow scroll doesn't create stacking context so those
    // containing block descendants may not be paint-order descendants, and the compositing dirty bits on RenderLayer act in paint order.
    if let paintParent = m_layer.stackingContext() {
      paintParent.setDescendantsNeedUpdateBackingAndHierarchyTraversal()
    }

    m_hasCompositedScrollableOverflow = hasCompositedScrollableOverflow
    if m_hasCompositedScrollableOverflow {
      m_layer.compositor().layerGainedCompositedScrollableOverflow(layer: m_layer)
    }
  }

  private var m_hasCompositedScrollableOverflow = false

  private let m_layer: RenderLayerWrapper
}
