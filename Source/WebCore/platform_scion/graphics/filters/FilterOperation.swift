/*
 * Copyright (C) 2011-2020 Apple Inc. All rights reserved.
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

class FilterOperationWrapper {
  enum `Type`: UInt8 {
    case Reference  // url(#somefilter)
    case Grayscale
    case Sepia
    case Saturate
    case HueRotate
    case Invert
    case AppleInvertLightness
    case Opacity
    case Brightness
    case Contrast
    case Blur
    case DropShadow
    case Passthrough
    case Default
    case None
  }

  func type() -> `Type` {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isIdentity() -> Bool { return false }

  func outsets() -> IntOutsets { return IntOutsets() }
}

class ReferenceFilterOperationWrapper: FilterOperationWrapper {
  func fragment() -> AtomStringWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func isIdentity() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func outsets() -> IntOutsets {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

// Grayscale, Sepia, Saturate and HueRotate are variations on a basic color matrix effect.
// For HueRotate, the angle of rotation is stored in m_amount.
class BasicColorMatrixFilterOperationWrapper: FilterOperationWrapper {}

// Invert, Brightness, Contrast and Opacity are variations on a basic component transfer effect.
class BasicComponentTransferFilterOperationWrapper: FilterOperationWrapper {}

class BlurFilterOperationWrapper: FilterOperationWrapper {}

class DropShadowFilterOperationWrapper: FilterOperationWrapper {}
