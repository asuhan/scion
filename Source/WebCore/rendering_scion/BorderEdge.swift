/*
 * Copyright (C) 2014 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation

struct BorderEdge {
  init(
    edgeWidth: Float32, edgeColor: ColorWrapper, edgeStyle: BorderStyle, edgeIsTransparent: Bool,
    edgeIsPresent: Bool, devicePixelRatio: Float32
  ) {
    self.color = edgeColor
    self.width = LayoutUnit(value: edgeWidth)
    self.devicePixelRatio = devicePixelRatio
    self.style = edgeStyle
    self.isTransparent = edgeIsTransparent
    self.isPresent = edgeIsPresent
    if edgeStyle == .Double && edgeWidth < borderWidthInDevicePixel(logicalPixels: 3) {
      style = .Solid
    }
    flooredToDevicePixelWidth = floorf(edgeWidth * devicePixelRatio) / devicePixelRatio
  }

  func hasVisibleColorAndStyle() -> Bool {
    return (style != .None && style != .Hidden) && !isTransparent
  }

  func presentButInvisible() -> Bool {
    return widthForPainting() != 0 && !hasVisibleColorAndStyle()
  }

  func widthForPainting() -> Float32 { return isPresent ? flooredToDevicePixelWidth : 0 }

  private func borderWidthInDevicePixel(logicalPixels: Int) -> Float32 {
    return LayoutUnit(value: Float32(logicalPixels) / devicePixelRatio).toFloat()
  }

  let color: ColorWrapper
  let width: LayoutUnit
  var flooredToDevicePixelWidth: Float32 = 0
  let devicePixelRatio: Float32
  var style: BorderStyle = .Hidden
  let isTransparent: Bool
  let isPresent: Bool
}

typealias BorderEdges = RectEdges<BorderEdge>

private func constructBorderEdge(
  width: Float32, borderColorProperty: CSSPropertyID, borderStyle: BorderStyle, isTransparent: Bool,
  isPresent: Bool, setColorsToBlack: Bool, style: RenderStyleWrapper, deviceScaleFactor: Float32
) -> BorderEdge {
  let color =
    setColorsToBlack
    ? ColorWrapper.black
    : style.visitedDependentColorWithColorFilter(colorProperty: borderColorProperty)
  return BorderEdge(
    edgeWidth: width, edgeColor: color, edgeStyle: borderStyle,
    edgeIsTransparent: !setColorsToBlack && isTransparent, edgeIsPresent: isPresent,
    devicePixelRatio: deviceScaleFactor)
}

func borderEdges(
  style: RenderStyleWrapper, deviceScaleFactor: Float32, setColorsToBlack: Bool = false,
  includeLogicalLeftEdge: Bool = true, includeLogicalRightEdge: Bool = true
) -> BorderEdges {
  let horizontal = style.isHorizontalWritingMode()
  return BorderEdges(
    top: constructBorderEdge(
      width: style.borderTopWidth(), borderColorProperty: .CSSPropertyBorderTopColor,
      borderStyle: style.borderTopStyle(),
      isTransparent: style.borderTopIsTransparent(),
      isPresent: horizontal || includeLogicalLeftEdge,
      setColorsToBlack: setColorsToBlack,
      style: style,
      deviceScaleFactor: deviceScaleFactor
    ),
    right: constructBorderEdge(
      width: style.borderRightWidth(), borderColorProperty: .CSSPropertyBorderRightColor,
      borderStyle: style.borderRightStyle(),
      isTransparent: style.borderRightIsTransparent(),
      isPresent: !horizontal || includeLogicalRightEdge,
      setColorsToBlack: setColorsToBlack,
      style: style,
      deviceScaleFactor: deviceScaleFactor),
    bottom: constructBorderEdge(
      width: style.borderBottomWidth(), borderColorProperty: .CSSPropertyBorderBottomColor,
      borderStyle: style.borderBottomStyle(),
      isTransparent: style.borderBottomIsTransparent(),
      isPresent: horizontal || includeLogicalRightEdge,
      setColorsToBlack: setColorsToBlack,
      style: style,
      deviceScaleFactor: deviceScaleFactor),
    left: constructBorderEdge(
      width: style.borderLeftWidth(), borderColorProperty: .CSSPropertyBorderLeftColor,
      borderStyle: style.borderLeftStyle(),
      isTransparent: style.borderLeftIsTransparent(),
      isPresent: !horizontal || includeLogicalLeftEdge,
      setColorsToBlack: setColorsToBlack,
      style: style,
      deviceScaleFactor: deviceScaleFactor)
  )
}
