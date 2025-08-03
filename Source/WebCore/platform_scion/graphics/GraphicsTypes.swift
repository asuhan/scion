/*
 * Copyright (C) 2004, 2005, 2006 Apple Inc.  All rights reserved.
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

enum CompositeOperator: UInt8 {
  case Clear
  case Copy
  case SourceOver
  case SourceIn
  case SourceOut
  case SourceAtop
  case DestinationOver
  case DestinationIn
  case DestinationOut
  case DestinationAtop
  case XOR
  case PlusDarker
  case PlusLighter
  case Difference
}

enum BlendMode: UInt8 {
  case Normal = 1  // Start with 1 to match SVG's blendmode enumeration.
  case Multiply
  case Screen
  case Darken
  case Lighten
  case Overlay
  case ColorDodge
  case ColorBurn
  case HardLight
  case SoftLight
  case Difference
  case Exclusion
  case Hue
  case Saturation
  case Color
  case Luminosity
  case PlusDarker
  case PlusLighter
}

enum DocumentMarkerLineStyleMode: UInt8 {
  case TextCheckingDictationPhraseWithAlternatives
  case Spelling
  case Grammar
  case AutocorrectionReplacement
  case DictationAlternatives
}

struct DocumentMarkerLineStyle {
  let mode: DocumentMarkerLineStyleMode
  let color: ColorWrapper
}

// InterpolationQuality::Default
// For ImagePaintingOptions, it means:
//  - Use context image interpolation quality.
// For GraphicsContext CG it means:
//  - If the CGImage has shouldInterpolate == true, use High
//  - Else use None
// For GraphicsContext Cairo it means:
//  - Use Medium
//
// FIXME: Remove InterpolationQuality::Default since it does not mean what it should
// obviously mean and because the CG context behavior is unusable in general case where
// the draw call sites cannot track where the native images are generated from.
enum InterpolationQuality: UInt8 {
  case Default
  case DoNotInterpolate
  case Low
  case Medium
  case High
}

enum LineCap: UInt8 {
  case Butt
  case Round
  case Square
}

enum LineJoin: UInt8 {
  case Miter
  case Round
  case Bevel
}

enum StrokeStyle: UInt8 {
  case NoStroke
  case SolidStroke
  case DottedStroke
  case DashedStroke
  case DoubleStroke
  case WavyStroke
}

struct TextDrawingModeFlags: OptionSet {
  let rawValue: UInt8

  static let Fill = TextDrawingModeFlags(rawValue: 1)
  static let Stroke = TextDrawingModeFlags(rawValue: 2)
}
