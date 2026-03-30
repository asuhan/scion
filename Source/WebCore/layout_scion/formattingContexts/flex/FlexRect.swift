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

struct FlexRect {
  struct Margins {
    var start = LayoutUnit()
    var end = LayoutUnit()
  }

  private init(
    top: LayoutUnit, left: LayoutUnit, width: LayoutUnit, height: LayoutUnit,
    mainAxisMargins: Margins, crossAxisMargins: Margins
  ) {
    m_rect = LayoutRectWrapper(x: left, y: top, width: width, height: height)
    m_mainAxisMargins = mainAxisMargins
    m_crossAxisMargins = crossAxisMargins
    #if ASSERT_ENABLED
      m_hasValidTop = true
      m_hasValidLeft = true
      m_hasValidWidth = true
      m_hasValidHeight = true
    #endif  // ASSERT_ENABLED
  }

  init(rect: LayoutRectWrapper, mainAxisMargins: Margins, crossAxisMargins: Margins) {
    self.init(
      top: rect.y(), left: rect.x(), width: rect.width(), height: rect.height(),
      mainAxisMargins: mainAxisMargins, crossAxisMargins: crossAxisMargins)
  }

  func top() -> LayoutUnit {
    #if ASSERT_ENABLED
      assert(m_hasValidTop)
    #endif  // ASSERT_ENABLED
    return m_rect.y()
  }

  func left() -> LayoutUnit {
    #if ASSERT_ENABLED
      assert(m_hasValidLeft)
    #endif  // ASSERT_ENABLED
    return m_rect.x()
  }

  func bottom() -> LayoutUnit {
    #if ASSERT_ENABLED
      assert(m_hasValidTop && m_hasValidHeight)
    #endif  // ASSERT_ENABLED
    return m_rect.maxY()
  }

  func right() -> LayoutUnit {
    #if ASSERT_ENABLED
      assert(m_hasValidLeft && m_hasValidWidth)
    #endif  // ASSERT_ENABLED
    return m_rect.maxX()
  }

  func width() -> LayoutUnit {
    #if ASSERT_ENABLED
      assert(m_hasValidWidth)
    #endif  // ASSERT_ENABLED
    return m_rect.width()
  }

  func height() -> LayoutUnit {
    #if ASSERT_ENABLED
      assert(m_hasValidHeight)
    #endif  // ASSERT_ENABLED
    return m_rect.height()
  }

  mutating func setTop(top: LayoutUnit) {
    #if ASSERT_ENABLED
      m_hasValidTop = true
    #endif  // ASSERT_ENABLED
    m_rect.setY(y: top)
  }

  #if ASSERT_ENABLED
    private let m_hasValidTop: Bool
    private let m_hasValidLeft: Bool
    private let m_hasValidWidth: Bool
    private let m_hasValidHeight: Bool
  #endif  // ASSERT_ENABLED
  private var m_rect: LayoutRectWrapper
  private let m_mainAxisMargins: Margins
  private let m_crossAxisMargins: Margins
}
