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

private func isRenderingMaskImage(_ object: RenderObjectWrapper) -> Bool {
  return object.view().frameView().paintBehavior().contains(.RenderingSVGClipOrMask)
}

class SVGRenderingContext {
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

  // Automatically finishes context rendering.
  deinit {
    // Fast path if we don't need to restore anything.
    if !m_renderingFlags.contains(SVGRenderingContext.ActionsNeeded) {
      return
    }

    assert(m_renderer != nil && m_paintInfo != nil)

    if m_renderingFlags.contains(.EndFilterLayer) {
      assert(m_filter != nil)
      let context = m_paintInfo!.context()
      m_filter!.postApplyResource(m_renderer!, context, [], nil, nil)
      m_paintInfo!.setContext(m_savedContext!)
      m_paintInfo!.rect = m_savedPaintRect
    }

    if m_renderingFlags.contains(.EndOpacityLayer) {
      m_paintInfo!.context().endTransparencyLayer()
    }

    if m_renderingFlags.contains(.RestoreGraphicsContext) {
      m_paintInfo!.context().restore()
    }
  }

  // Used by all SVG renderers who apply clip/filter/etc. resources to the renderer content.
  func prepareToRenderSVGContent(
    _ renderer: RenderElementWrapper, _ paintInfo: PaintInfoWrapper,
    _ needsGraphicsContextSave: NeedsGraphicsContextSave = .DontSaveGraphicsContext
  ) {
    m_renderer = renderer
    m_paintInfo = paintInfo
    m_filter = nil

    // We need to save / restore the context even if the initialization failed.
    if needsGraphicsContextSave == .SaveGraphicsContext {
      m_paintInfo!.context().save()
      m_renderingFlags.update(with: .RestoreGraphicsContext)
    }

    let style = m_renderer!.style()

    // Setup transparency layers before setting up SVG resources!
    let isRenderingMask = isRenderingMaskImage(m_renderer!)
    // RenderLayer takes care of root opacity.
    let opacity = (renderer.isLegacyRenderSVGRoot() || isRenderingMask) ? 1 : style.opacity()
    let hasBlendMode = style.hasBlendMode()
    let hasIsolation = style.hasIsolation()
    var isolateMaskForBlending = false

    if style.hasPositionedMask(),
      let graphicsElement = renderer.element() as? SVGGraphicsElementWrapper
    {
      isolateMaskForBlending = graphicsElement.shouldIsolateBlending()
    }

    if opacity < 1 || hasBlendMode || isolateMaskForBlending || hasIsolation {
      let repaintRect = m_renderer!.repaintRectInLocalCoordinates()
      m_paintInfo!.context().clip(rect: repaintRect)

      if opacity < 1 || hasBlendMode || isolateMaskForBlending || hasIsolation {

        if hasBlendMode {
          m_paintInfo!.context().setCompositeOperation(
            operation: m_paintInfo!.context().compositeOperation(), blendMode: style.blendMode())
        }

        m_paintInfo!.context().beginTransparencyLayer(opacity: opacity)

        if hasBlendMode {
          m_paintInfo!.context().setCompositeOperation(
            operation: m_paintInfo!.context().compositeOperation(), blendMode: .Normal)
        }

        m_renderingFlags.update(with: .EndOpacityLayer)
      }
    }

    let hasSimpleClip =
      style.clipPath() is ShapePathOperation || style.clipPath() is BoxPathOperation
    if hasSimpleClip && !(renderer is LegacyRenderSVGRootWrapper) {
      SVGRenderSupport.clipContextToCSSClippingArea(m_paintInfo!.context(), renderer)
    }

    // FIXME: Text painting under LBSE reaches this code path, since all text painting code is shared between legacy / LBSE.
    var resources: SVGResources? = nil
    if !renderer.document().settings().layerBasedSVGEngineEnabled() {
      resources = SVGResourcesCache.cachedResourcesForRenderer(m_renderer!)
    }

    if resources == nil {
      if style.hasReferenceFilterOnly() {
        return
      }

      m_renderingFlags.update(with: .RenderingPrepared)
      return
    }

    if !isRenderingMask, let masker = resources!.masker() {
      let context = m_paintInfo!.context()
      let result = masker.applyResource(m_renderer!, style, context, [])
      m_paintInfo!.setContext(context)
      if !resourceWasApplied(result) {
        return
      }
    }

    if let clipper = resources!.clipper(),
      !hasSimpleClip && !(renderer is LegacyRenderSVGRootWrapper)
    {
      let context = m_paintInfo!.context()
      let result = clipper.applyResource(m_renderer!, style, context, [])
      m_paintInfo!.setContext(context)
      if !resourceWasApplied(result) {
        return
      }

      m_pathClippingIsEntirelyWithinRendererContents = result.contains(.ClipContainsRendererContent)
    }

    if !isRenderingMask {
      m_filter = resources!.filter()
      if m_filter != nil && !m_filter!.isIdentity() {
        m_savedContext = m_paintInfo!.context()
        m_savedPaintRect = m_paintInfo!.rect
        // Return with false here may mean that we don't need to draw the content
        // (because it was either drawn before or empty) but we still need to apply the filter.
        m_renderingFlags.update(with: .EndFilterLayer)
        let context = m_paintInfo!.context()
        let result = m_filter!.applyResource(m_renderer!, style, context, [])
        m_paintInfo!.setContext(context)
        if !resourceWasApplied(result) {
          return
        }

        // Since we're caching the resulting bitmap and do not invalidate it on repaint rect
        // changes, we need to paint the whole filter region. Otherwise, elements not visible
        // at the time of the initial paint (due to scrolling, window size, etc.) will never
        // be drawn.
        m_paintInfo!.rect = LayoutRectWrapper(rect: IntRect(m_filter!.drawingRegion(m_renderer!)))
      }
    }

    m_renderingFlags.update(with: .RenderingPrepared)
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

  private struct RenderingFlags: OptionSet {
    let rawValue: UInt8
    static let RenderingPrepared = RenderingFlags(rawValue: 1 << 0)
    static let RestoreGraphicsContext = RenderingFlags(rawValue: 1 << 1)
    static let EndOpacityLayer = RenderingFlags(rawValue: 1 << 2)
    static let EndFilterLayer = RenderingFlags(rawValue: 1 << 3)
    static let PrepareToRenderSVGContentWasCalled = RenderingFlags(rawValue: 1 << 4)
  }

  // List of those flags which require actions during the destructor.
  private static let ActionsNeeded: RenderingFlags = [
    .RestoreGraphicsContext, .EndOpacityLayer, .EndFilterLayer,
  ]

  private var m_renderer: RenderElementWrapper? = nil
  private var m_paintInfo: PaintInfoWrapper? = nil
  private var m_savedContext: GraphicsContextWrapper? = nil
  private var m_filter: LegacyRenderSVGResourceFilter? = nil
  private var m_savedPaintRect = LayoutRectWrapper()
  private var m_renderingFlags: RenderingFlags = []
  // True with path-based clipping is known to contrain the clipped area to within the renderer; used to optimize away a context clip.
  private var m_pathClippingIsEntirelyWithinRendererContents = false
}
