/*
 * Copyright (C) 2023 Apple Inc.  All rights reserved.
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

class ImagePaintingOptionsWrapper {
  init() {}

  init(
    compositeOperator: CompositeOperator, blendMode: BlendMode, decodingMode: DecodingMode,
    orientation: ImageOrientation.Orientation, interpolationQuality: InterpolationQuality,
    allowImageSubsampling: AllowImageSubsampling, showDebugBackground: ShowDebugBackground
  ) {
    self.compositeOperator = compositeOperator
    self.blendMode = blendMode
    self.decodingMode = decodingMode
    self.orientation = orientation
    self.interpolationQuality = interpolationQuality
    self.allowImageSubsampling = allowImageSubsampling
    self.showDebugBackground = showDebugBackground
  }

  init(
    compositeOperator: CompositeOperator, decodingMode: DecodingMode,
    orientation: ImageOrientation, interpolationQuality: InterpolationQuality,
    allowImageSubsampling: AllowImageSubsampling, showDebugBackground: ShowDebugBackground
  ) {
    self.compositeOperator = compositeOperator
    self.decodingMode = decodingMode
    self.orientation = orientation.orientation()
    self.interpolationQuality = interpolationQuality
    self.allowImageSubsampling = allowImageSubsampling
    self.showDebugBackground = showDebugBackground
  }

  init(_ orientation: ImageOrientation) {
    self.orientation = orientation.orientation()
  }

  init(_ compositeOperator: CompositeOperator) {
    self.compositeOperator = compositeOperator
  }

  private(set) var blendMode: BlendMode = .Normal
  private(set) var decodingMode: DecodingMode = .Synchronous
  private(set) var compositeOperator: CompositeOperator = .SourceOver
  private(set) var orientation: ImageOrientation.Orientation = .None
  private(set) var interpolationQuality: InterpolationQuality = .Default
  private(set) var allowImageSubsampling: AllowImageSubsampling = .No
  private(set) var showDebugBackground: ShowDebugBackground = .No
}
