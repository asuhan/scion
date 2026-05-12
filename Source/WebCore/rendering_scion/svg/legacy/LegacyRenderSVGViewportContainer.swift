/*
 * Copyright (C) 2004, 2005, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2007 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Google, Inc.
 * Copyright (C) 2009 Apple Inc. All rights reserved.
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

// This is used for non-root <svg> elements and <marker> elements, neither of which are SVGTransformable
// thus we inherit from LegacyRenderSVGContainer instead of LegacyRenderSVGTransformableContainer
final class LegacyRenderSVGViewportContainer: LegacyRenderSVGContainer {
  override func didTransformToRootUpdate() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func determineIfLayoutSizeChanged() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func setNeedsTransformUpdate() { needsTransformUpdate = true }

  override func localToParentTransform() -> AffineTransform {
    assert(isNativeImpl())
    return m_localToParentTransform
  }

  override func calcViewport() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  override func calculateLocalTransform() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func applyViewportClip(_ paintInfo: PaintInfoWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let isLayoutSizeChanged = false
  private var needsTransformUpdate = false

  private let m_localToParentTransform = AffineTransform()
}
