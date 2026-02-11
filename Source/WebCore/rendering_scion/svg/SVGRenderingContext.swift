/*
 * Copyright (C) 2007, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Google, Inc.  All rights reserved.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
 * Copyright (C) 2018 Adobe Systems Incorporated. All rights reserved.
 * Copyright (C) 2022 Apple Inc. All rights reserved.
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

struct SVGRenderingContext: ~Copyable {
  enum NeedsGraphicsContextSave {
    case SaveGraphicsContext
    case DontSaveGraphicsContext
  }

  // Does not start rendering.
  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(
    _ object: RenderElementWrapper, _ paintinfo: PaintInfoWrapper,
    _ needsGraphicsContextSave: NeedsGraphicsContextSave = .DontSaveGraphicsContext
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Used by all SVG renderers who apply clip/filter/etc. resources to the renderer content.
  func prepareToRenderSVGContent(
    _ renderer: RenderElementWrapper, _ paintInfo: PaintInfoWrapper,
    _ needsGraphicsContextSave: NeedsGraphicsContextSave = .DontSaveGraphicsContext
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderingPrepared() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pathClippingIsEntirelyWithinRendererContents() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func calculateScreenFontSizeScalingFactor(_ renderer: RenderObjectWrapper) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Support for the buffered-rendering hint.
  func bufferForeground(_ imageBuffer: ImageBufferWrapper?) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
