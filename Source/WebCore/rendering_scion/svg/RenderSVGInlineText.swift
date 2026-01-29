/*
 * Copyright (C) 2006 Oliver Hunt <ojh16@student.canterbury.ac.nz>
 * Copyright (C) 2006-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2015 Google Inc. All rights reserved.
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2008 Rob Buis <buis@kde.org>
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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

private func applySVGWhitespaceRules(_ string: StringWrapper, _ preserveWhiteSpace: Bool)
  -> StringWrapper
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

final class RenderSVGInlineTextWrapper: RenderTextWrapper {
  func characterStartsNewTextChunk(_ position: UInt32) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layoutAttributes() -> SVGTextLayoutAttributes {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scalingFactor() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scaledFont() -> FontCascadeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateScaledFont() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    updateScaledFont()

    let newPreserves = style().whiteSpaceCollapse() == .Preserve
    let oldPreserves = oldStyle != nil ? oldStyle!.whiteSpaceCollapse() == .Preserve : false
    if oldPreserves && !newPreserves {
      setText(newContent: applySVGWhitespaceRules(originalText(), false), force: true)
      return
    }

    if !oldPreserves && newPreserves {
      setText(newContent: applySVGWhitespaceRules(originalText(), true), force: true)
      return
    }

    if diff != .Layout {
      return
    }

    // The text metrics may be influenced by style changes.
    if let textAncestor = RenderSVGTextWrapper.locateRenderSVGTextAncestor(start: self) {
      textAncestor.setNeedsLayout()
    }
  }

  override func objectBoundingBox() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
