/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
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

final class RenderListItemWrapper: RenderBlockFlowWrapper {
  init(_ element: ElementWrapper, _ style: RenderStyleWrapper) {
    super.init(type: .ListItem, element: element, style: style)
    assert(isRenderListItem())
    setInline(false)
  }

  override init(p: UnsafeMutableRawPointer) { super.init(p: p) }

  deinit {
    // Do not add any code here. Add it to willBeDestroyed() instead.
    assert(m_marker == nil)
  }

  func value() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateListMarkerNumbers() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeMarkerStyle() -> RenderStyleWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func markerRenderer() -> RenderListMarkerWrapper? {
    assert(isNativeImpl())
    return m_marker
  }

  func setMarkerRenderer(marker: RenderListMarkerWrapper) {
    assert(isNativeImpl())
    m_marker = marker
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(isNativeImpl())
    if !logicalHeight().bool() && hasNonVisibleOverflow() {
      return
    }

    super.paint(paintInfo: &paintInfo, paintOffset: paintOffset)
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    if !isNativeImpl() {
      wk_interop.RenderListItem_layout(id())
      return
    }
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    super.layout()
  }

  override final func computePreferredLogicalWidths() {
    assert(isNativeImpl())
    // FIXME: RenderListMarker::updateMargins() mutates margin style which affects preferred widths.
    if m_marker?.preferredLogicalWidthsDirty() ?? false {
      m_marker!.updateMarginsAndContent()
    }

    super.computePreferredLogicalWidths()
  }

  private var m_marker: RenderListMarkerWrapper?
}

func isHTMLListElement(node: NodeWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
