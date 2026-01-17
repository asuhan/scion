/*
 * Copyright (C) 2006-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Alexander Kellett <lypanov@kde.org>
 * Copyright (C) 2006 Oliver Hunt <ojh16@student.canterbury.ac.nz>
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2008 Rob Buis <buis@kde.org>
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) Research In Motion Limited 2010-2012. All rights reserved.
 * Copyright (C) 2012-2023 Google Inc.
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

final class RenderSVGTextWrapper: RenderSVGBlockWrapper {
  static func locateRenderSVGTextAncestor(start: RenderObjectWrapper) -> RenderSVGTextWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func subtreeChildWasAdded(child: RenderObjectWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func subtreeChildWillBeRemoved(
    child: RenderObjectWrapper, affectedAttributes: inout [SVGTextLayoutAttributes]
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func subtreeChildWasRemoved(affectedAttributes: [SVGTextLayoutAttributes]) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
