/*
 * Copyright (C) 2004-2017 Apple Inc. All rights reserved.
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

private func writeTextRun(
  _ textRenderer: RenderTextWrapper, _ textRun: InlineIterator.TextBox, _ ts: TextStream
) {
  let rect = textRun.visualRectIgnoringBlockDirection()
  let x = Int32(rect.x())
  var y = Int32(rect.y())
  // FIXME: Use non-logical width. webkit.org/b/206809.
  let logicalWidth =
    Int32((rect.x() + (textRun.isHorizontal() ? rect.width() : rect.height())).rounded(.up)) - x
  // FIXME: Table cell adjustment is temporary until results can be updated.
  if let tableCell = textRenderer.containingBlock() as? RenderTableCellWrapper {
    y -= floorToInt(value: tableCell.intrinsicPaddingBefore())
  }

  ts <<< "text run at (" <<< x <<< "," <<< y <<< ") width " <<< logicalWidth
  if !textRun.isLeftToRightDirection() {
    ts <<< " RTL"
  }
  // TODO(asuhan): apply quoteAndEscapeNonPrintables if needed
  ts <<< ": " <<< textRun.originalText()
  if textRun.hasHyphen() {
    ts <<< " + hyphen string " <<< textRenderer.style().hyphenString().string()
  }
  ts <<< "\n"
}

func writeTextRuns(_ text: RenderTextWrapper, _ ts: TextStream) {
  for run in InlineIterator.textBoxesFor(text) {
    ts.indent()
    writeTextRun(text, run, ts)
  }
}
