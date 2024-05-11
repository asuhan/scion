/*
 * Copyright (C) 2020 Apple Inc. All rights reserved.
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

class InlineTextBoxWrapper: BoxWrapper {
  init(
    content: StringWrapper, isCombined: Bool, canUseSimplifiedContentMeasuring: Bool,
    canUseSimpleFontCodePath: Bool, hasPositionDependentContentWidth: Bool,
    hasStrongDirectionalityContent: Bool,
    style: RenderStyleWrapper
  ) {
    self.content = content
    self.isCombined = isCombined
    if canUseSimplifiedContentMeasuring {
      contentCharacteristicSet.insert(.CanUseSimplifiedContentMeasuring)
    }
    if canUseSimpleFontCodePath {
      contentCharacteristicSet.insert(.CanUseSimpledFontCodepath)
    }
    if hasPositionDependentContentWidth {
      contentCharacteristicSet.insert(.HasPositionDependentContentWidth)
    }
    if hasStrongDirectionalityContent {
      contentCharacteristicSet.insert(.HasStrongDirectionalityContent)
    }
    super.init(style: style)
  }

  init() {}

  struct ContentCharacteristicSet: OptionSet {
    let rawValue: UInt32
    static let CanUseSimplifiedContentMeasuring = ContentCharacteristicSet(rawValue: 1 << 0)
    static let CanUseSimpledFontCodepath = ContentCharacteristicSet(rawValue: 1 << 1)
    static let HasPositionDependentContentWidth = ContentCharacteristicSet(rawValue: 1 << 2)
    static let HasStrongDirectionalityContent = ContentCharacteristicSet(rawValue: 1 << 3)
  }

  // FIXME: This should not be a box's property.
  func canUseSimplifiedContentMeasuring() -> Bool {
    return contentCharacteristicSet.contains(.CanUseSimplifiedContentMeasuring)
  }

  func canUseSimpleFontCodePath() -> Bool {
    return contentCharacteristicSet.contains(.CanUseSimpledFontCodepath)
  }

  func hasPositionDependentContentWidth() -> Bool {
    return contentCharacteristicSet.contains(.HasPositionDependentContentWidth)
  }

  func hasStrongDirectionalityContent() -> Bool {
    return contentCharacteristicSet.contains(.HasStrongDirectionalityContent)
  }

  var content: StringWrapper = StringWrapper()
  var isCombined: Bool = false
  var contentCharacteristicSet = ContentCharacteristicSet(rawValue: 0)
}
