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

final class RenderListItemWrapper: RenderBlockFlowWrapper {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMarkerRenderer(marker: RenderListMarkerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
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

  override final func computePreferredLogicalWidths() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

func isHTMLListElement(node: NodeWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
