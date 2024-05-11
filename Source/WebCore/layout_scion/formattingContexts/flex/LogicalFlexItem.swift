/*
 * Copyright (C) 2022 Apple Inc. All rights reserved.
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

struct LogicalFlexItem {
  init(
    flexItem: ElementBoxWrapper, mainGeometry: MainAxisGeometry, crossGeometry: CrossAxisGeometry,
    hasAspectRatio: Bool, isOrhogonal: Bool
  ) {
    self.layoutBox = flexItem
    self.mainAxisGeometry = mainGeometry
    self.crossAxisGeometry = crossGeometry
    self.hasAspectRatio = hasAspectRatio
    self.isOrhogonal = isOrhogonal
  }

  init() {}

  struct MainAxisGeometry {
    func margin() -> LayoutUnit {
      return (marginStart ?? LayoutUnit(value: 0)) + (marginEnd ?? LayoutUnit(value: 0))
    }

    var definiteFlexBasis: LayoutUnit? = nil

    var maximumSize: LayoutUnit? = nil
    var minimumSize: LayoutUnit? = nil

    var marginStart: LayoutUnit? = nil
    var marginEnd: LayoutUnit? = nil

    var borderAndPadding = LayoutUnit()
  }

  struct CrossAxisGeometry {
    func margin() -> LayoutUnit {
      return (marginStart ?? LayoutUnit(value: 0)) + (marginEnd ?? LayoutUnit(value: 0))
    }

    func hasNonAutoMargins() -> Bool {
      return marginStart != nil || marginEnd != nil
    }

    var definiteSize: LayoutUnit? = nil

    var ascent = LayoutUnit()
    var descent = LayoutUnit()

    var maximumSize: LayoutUnit? = nil
    var minimumSize: LayoutUnit? = nil

    var marginStart: LayoutUnit? = nil
    var marginEnd: LayoutUnit? = nil

    var borderAndPadding = LayoutUnit()

    var hasSizeAuto = false
  }

  func mainAxis() -> MainAxisGeometry {
    return mainAxisGeometry
  }

  func crossAxis() -> CrossAxisGeometry {
    return crossAxisGeometry
  }

  func growFactor() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shrinkFactor() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasContentFlexBasis() -> Bool {
    return style().flexBasis().isContent()
  }

  func hasAvailableSpaceDependentFlexBasis() -> Bool {
    return false
  }

  func isContentBoxBased() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func style() -> RenderStyleWrapper {
    return layoutBox!.style
  }

  var layoutBox: ElementBoxWrapper? = nil

  var mainAxisGeometry = MainAxisGeometry()
  var crossAxisGeometry = CrossAxisGeometry()
  var hasAspectRatio = false
  var isOrhogonal = false
}
