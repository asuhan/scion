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

class LineBoxIteratorLegacyPath {
  init(_ rootInlineBox: LegacyRootInlineBox) { m_rootInlineBox = rootInlineBox }

  func contentLogicalTop() -> Float32 { return m_rootInlineBox!.lineTop.toFloat() }

  func contentLogicalBottom() -> Float32 { return m_rootInlineBox!.lineBottom.toFloat() }

  func logicalTop() -> Float32 { return m_rootInlineBox!.lineBoxTop.toFloat() }

  func logicalBottom() -> Float32 { return m_rootInlineBox!.lineBoxBottom.toFloat() }

  func inkOverflowLogicalTop() -> Float32 {
    return m_rootInlineBox!.logicalTopVisualOverflow().float()
  }

  func inkOverflowLogicalBottom() -> Float32 {
    return m_rootInlineBox!.logicalBottomVisualOverflow().float()
  }

  func contentLogicalLeft() -> Float32 { return m_rootInlineBox!.logicalLeft() }

  func formattingContextRoot() -> RenderBlockFlowWrapper { m_rootInlineBox!.blockFlow() }

  func lineIndex() -> UInt64 { return formattingContextRoot().legacyRootBox() != nil ? 1 : 0 }

  private let m_rootInlineBox: LegacyRootInlineBox?
}
