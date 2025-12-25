/*
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2007-2008 Torch Mobile, Inc.
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

class PathWrapper {
  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(points: [FloatPoint]) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func moveTo(point: FloatPoint) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addBezierCurveTo(controlPoint1: FloatPoint, controlPoint2: FloatPoint, endPoint: FloatPoint)
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addRect(rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addRoundedRect(
    roundedRect: FloatRoundedRect, strategy: PathRoundedRect.Strategy = .PreferNative
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addRoundedRect(rect: RoundedRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func length() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boundingRect() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
