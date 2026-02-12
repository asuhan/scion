/*
 * Copyright (C) 2006 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2007-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2010 Torch Mobile (Beijing) Co. Ltd. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
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

struct ImageBufferOptions: OptionSet {
  let rawValue: UInt8
  static let Accelerated = ImageBufferOptions(rawValue: 1 << 0)
  static let AvoidBackendSizeCheckForTesting = ImageBufferOptions(rawValue: 1 << 1)
}

class ImageBufferWrapper {
  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func create(
    _ size: FloatSize, _ purpose: RenderingPurpose, _ resolutionScale: Float32,
    _ colorSpace: DestinationColorSpace, _ pixelFormat: ImageBufferPixelFormat,
    _ options: ImageBufferOptions = [], _ graphicsClient: GraphicsClientWrapper? = nil
  ) -> ImageBufferWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func context() -> GraphicsContextWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func backendSize() -> IntSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func getPixelBuffer(_ destinationFormat: PixelBufferFormat, _ sourceRect: IntRect)
    -> PixelBufferWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
