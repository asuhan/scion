/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2012-2019 Apple Inc. All rights reserved.
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

struct ImageOrientation: Equatable {
  enum Orientation: UInt8 {
    case FromImage = 0  // Orientation from the image should be respected.

    // This range intentionally matches the orientation values from the EXIF spec.
    // See JEITA CP-3451, page 18. http://www.exif.org/Exif2-2.PDF
    case OriginTopLeft = 1  // default
    case OriginTopRight = 2  // mirror along y-axis
    case OriginBottomRight = 3  // 180 degree rotation
    case OriginBottomLeft = 4  // mirror along the x-axis
    case OriginLeftTop = 5  // mirror along x-axis + 270 degree CW rotation
    case OriginRightTop = 6  // 90 degree CW rotation
    case OriginRightBottom = 7  // mirror along x-axis + 90 degree CW rotation
    case OriginLeftBottom = 8  // 270 degree CW rotation

    static var None: Orientation {
      return .OriginTopLeft
    }
  }

  init(orientation: Orientation) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
