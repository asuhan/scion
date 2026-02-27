/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
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
 *
 */

class StyleRareInheritedData {
  func copy() -> StyleRareInheritedData {
    let c = StyleRareInheritedData()
    c.indent = indent
    c.nbspMode = nbspMode
    c.lineBreak = lineBreak
    c.lineSnap = lineSnap
    c.lineAlign = lineAlign
    c.hyphens = hyphens
    c.textEmphasisPosition = textEmphasisPosition
    c.textIndentLine = textIndentLine
    c.textIndentType = textIndentType
    c.textAlignLast = textAlignLast
    c.rubyPosition = rubyPosition
    c.rubyAlign = rubyAlign
    c.rubyOverhang = rubyOverhang
    c.tabSize = tabSize
    c.wordBreak = wordBreak
    c.overflowWrap = overflowWrap
    c.hyphenationLimitLines = hyphenationLimitLines
    return c
  }

  var indent = LengthWrapper()
  var nbspMode = false
  var lineBreak: LineBreak = .Auto
  var lineSnap: LineSnap = .None
  var lineAlign: LineAlign = .None
  var hyphens: Hyphens = .None
  var textEmphasisPosition = TextEmphasisPosition()
  var textIndentLine: TextIndentLine = .FirstLine
  var textIndentType: TextIndentType = .Normal
  var textAlignLast: TextAlignLast = .Auto
  var rubyPosition: RubyPosition = .Over
  var rubyAlign: RubyAlign = .Start
  var rubyOverhang: RubyOverhang = .Auto
  var tabSize: TabSizeWrapper = TabSizeWrapper(numOrLength: 0, isSpaces: .LengthValueType)
  var wordBreak: WordBreak = .Normal
  var overflowWrap: OverflowWrap = .Normal
  var hyphenationLimitLines: Int16 = -1
}
