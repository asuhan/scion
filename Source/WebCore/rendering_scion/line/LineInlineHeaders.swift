/**
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All right reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2013 ChangSeok Oh <shivamidow@gmail.com>
 * Copyright (C) 2013 Adobe Systems Inc. All right reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

enum WhitespacePosition {
  case LeadingWhitespace
  case TrailingWhitespace
}

private func lineStyle(_ renderer: RenderObjectWrapper, _ lineInfo: LineInfo) -> RenderStyleWrapper
{
  return lineInfo.isFirstLine ? renderer.firstLineStyle() : renderer.style()
}

private func requiresLineBoxForContent(_ flow: RenderInlineWrapper, _ lineInfo: LineInfo) -> Bool {
  let parent = flow.parent()!
  if flow.document().inNoQuirksMode() {
    let flowStyle = lineStyle(flow, lineInfo)
    let parentStyle = lineStyle(parent, lineInfo)
    if flowStyle.lineHeight() != parentStyle.lineHeight()
      || flowStyle.verticalAlign() != parentStyle.verticalAlign()
      || !parentStyle.fontCascade().metricsOfPrimaryFont().hasIdenticalAscentDescentAndLineGap(
        flowStyle.fontCascade().metricsOfPrimaryFont())
    {
      return true
    }
  }
  return false
}

private func shouldCollapseWhiteSpace(
  _ style: RenderStyleWrapper, _ lineInfo: LineInfo, _ whitespacePosition: WhitespacePosition
) -> Bool {
  // CSS2 16.6.1
  // If a space (U+0020) at the beginning of a line has 'white-space' set to 'normal', 'nowrap', or 'pre-line', it is removed.
  // If a space (U+0020) at the end of a line has 'white-space' set to 'normal', 'nowrap', or 'pre-line', it is also removed.
  // If spaces (U+0020) or tabs (U+0009) at the end of a line have 'white-space' set to 'pre-wrap', UAs may visually collapse them.
  return style.collapseWhiteSpace()
    || (whitespacePosition == .TrailingWhitespace && style.whiteSpace() == .PreWrap
      && !lineInfo.isEmpty)
}

private func skipNonBreakingSpace(_ it: LegacyInlineIterator, _ lineInfo: LineInfo) -> Bool {
  if it.renderer()!.style().nbspMode() != .Space
    || it.current() != CharacterNames.Unicode.noBreakSpace
  {
    return false
  }

  // FIXME: This is bad. It makes nbsp inconsistent with space and won't work correctly
  // with m_minWidth/m_maxWidth.
  // Do not skip a non-breaking space if it is the first character
  // on a line after a clean line break (or on the first line, since previousLineBrokeCleanly starts off
  // |true|).
  if lineInfo.isEmpty {
    return false
  }

  return true
}

func requiresLineBox(
  it: LegacyInlineIterator, lineInfo: LineInfo = LineInfo(),
  whitespacePosition: WhitespacePosition = .LeadingWhitespace
) -> Bool {
  var rendererIsEmptyInline = false
  if let inlineRenderer = it.renderer() as? RenderInlineWrapper {
    if !requiresLineBoxForContent(inlineRenderer, lineInfo) {
      return false
    }
    rendererIsEmptyInline = isEmptyInline(inlineRenderer)
  }

  if !shouldCollapseWhiteSpace(it.renderer()!.style(), lineInfo, whitespacePosition) {
    return true
  }

  let current = it.current()
  let notJustWhitespace =
    current != UChar(Character(" ").asciiValue!) && current != UChar(Character("\t").asciiValue!)
    && current != CharacterNames.Unicode.softHyphen
    && (current != UChar(Character("\n").asciiValue!) || it.renderer()!.preservesNewline())
    && !skipNonBreakingSpace(it, lineInfo)
  return notJustWhitespace || rendererIsEmptyInline
}
