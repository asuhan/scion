/*
 * Copyright (C) 2014-2021 Apple Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

func wavyOffsetFromDecoration() -> Float32 {
  return 1
}

struct WavyStrokeParameters {
  // Distance between decoration's axis and Bezier curve's control points.
  // The height of the curve is based on this distance. Increases the curve's height
  // as fontSize increases to make the curve look better.
  let controlPointDistance: Float32

  // Increment used to form the diamond shape between start point (p1), control
  // points and end point (p2) along the axis of the decoration. The curve gets
  // wider as font size increases.
  let step: Float32
}

func wavyStrokeParameters(fontSize: Float32) -> WavyStrokeParameters {
  // More information is in the WavyStrokeParameters definition.
  return WavyStrokeParameters(controlPointDistance: fontSize * 1.5 / 16, step: fontSize / 4.5)
}

struct TextUnderlinePositionUnder {
  var textRunLogicalHeight: Float32 = 0
  // This offset value is the distance between the current text run's logical bottom and the lowest position of all the text runs
  // on line that belong to the same decorating box.
  var textRunOffsetFromBottomMost: Float32 = 0
}

func visualOverflowForDecorations(style: RenderStyleWrapper) -> GlyphOverflow {
  if style.p == nil {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
  let glyphOverflowRaw = wk_interop.visualOverflowForDecorationsByStyle(style.p)
  return GlyphOverflow(
    left: LayoutUnit.fromRawValue(value: glyphOverflowRaw.left),
    right: LayoutUnit.fromRawValue(value: glyphOverflowRaw.right),
    top: LayoutUnit.fromRawValue(value: glyphOverflowRaw.top),
    bottom: LayoutUnit.fromRawValue(value: glyphOverflowRaw.bottom)
  )
}

func visualOverflowForDecorations(
  style: RenderStyleWrapper, textUnderlinePositionUnder: TextUnderlinePositionUnder
) -> GlyphOverflow {
  if style.p == nil {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
  let glyphOverflowRaw = wk_interop.visualOverflowForDecorations(
    style.p, textUnderlinePositionUnder.textRunLogicalHeight,
    textUnderlinePositionUnder.textRunOffsetFromBottomMost)
  return GlyphOverflow(
    left: LayoutUnit.fromRawValue(value: glyphOverflowRaw.left),
    right: LayoutUnit.fromRawValue(value: glyphOverflowRaw.right),
    top: LayoutUnit.fromRawValue(value: glyphOverflowRaw.top),
    bottom: LayoutUnit.fromRawValue(value: glyphOverflowRaw.bottom)
  )
}

func underlineOffsetForTextBoxPainting(
  inlineBox: InlineIterator.InlineBox, style: RenderStyleWrapper
) -> Float32 {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
