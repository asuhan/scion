/*
 * Copyright (C) 2023 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

class RegionContext {
  func pushTransform(transform: AffineTransform) {
    if transformStack.isEmpty {
      transformStack.append(transform)
    } else {
      transformStack.append(transformStack.last! * transform)
    }
  }

  func popTransform() {
    if transformStack.isEmpty {
      fatalError("Not reached")
    }
    transformStack.removeLast()
  }

  func pushClip(clipRect: IntRect) {
    let transformedClip =
      transformStack.isEmpty ? clipRect : transformStack.last!.mapRect(rect: clipRect)

    if clipStack.isEmpty {
      clipStack.append(transformedClip)
    } else {
      clipStack.append(intersection(a: clipStack.last!, b: transformedClip))
    }
  }

  func pushClip(path: PathWrapper) {
    // FIXME: Approximate paths better.
    let pathBounds = enclosingIntRect(rect: path.boundingRect())
    pushClip(clipRect: pathBounds)
  }

  func popClip() {
    if clipStack.isEmpty {
      fatalError("Not reached")
    }
    clipStack.removeLast()
  }

  private var transformStack: [AffineTransform] = []
  private var clipStack: [IntRect] = []
}

class RegionContextStateSaver {
  init(context: RegionContext?) {
    self.context = context
  }

  deinit {
    if context == nil {
      return
    }

    if pushedClip {
      context!.popClip()
    }
  }

  func pushClip(clipRect: IntRect) {
    assert(!pushedClip)
    if let context = context {
      context.pushClip(clipRect: clipRect)
    }
    pushedClip = true
  }

  func pushClip(path: PathWrapper) {
    assert(!pushedClip)
    if let context = context {
      context.pushClip(path: path)
    }
    pushedClip = true
  }

  private var context: RegionContext?
  private var pushedClip = false
}
