/*
 * Copyright (C) 2006 Apple Inc.  All rights reserved.
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

// scrollPosition is in content coordinates (0,0 is at scrollOrigin), so may have negative components.
typealias ScrollPosition = IntPoint
// scrollOffset() is the value used by scrollbars (min is 0,0), and should never have negative components.
typealias ScrollOffset = IntPoint

enum ScrollType {
  case User
  case Programmatic
}

enum OverscrollBehavior: UInt8 {
  case Auto
  case Contain
  case None
}

enum ScrollAnimationStatus {
  case NotAnimating
  case Animating
}

enum ScrollbarOrientation: UInt8 {
  case Horizontal
  case Vertical
}

enum ScrollbarMode: UInt8 {
  case Auto
  case AlwaysOff
  case AlwaysOn
}

enum ScrollbarExpansionState: UInt8 {
  case Regular
  case Expanded
}

enum ScrollbarWidth: UInt8 {
  case Auto
  case Thin
  case None
}

struct ScrollbarPart: OptionSet {
  let rawValue: UInt16

  static let NoPart: ScrollbarPart = []
  static let BackButtonStartPart = ScrollbarPart(rawValue: 1 << 0)
  static let ForwardButtonStartPart = ScrollbarPart(rawValue: 1 << 1)
  static let BackTrackPart = ScrollbarPart(rawValue: 1 << 2)
  static let ThumbPart = ScrollbarPart(rawValue: 1 << 3)
  static let ForwardTrackPart = ScrollbarPart(rawValue: 1 << 4)
  static let BackButtonEndPart = ScrollbarPart(rawValue: 1 << 5)
  static let ForwardButtonEndPart = ScrollbarPart(rawValue: 1 << 6)
  static let ScrollbarBGPart = ScrollbarPart(rawValue: 1 << 7)
  static let TrackBGPart = ScrollbarPart(rawValue: 1 << 8)
  static let AllParts: ScrollbarPart = [
    .BackButtonStartPart, .ForwardButtonStartPart, .BackTrackPart, .ThumbPart, .ForwardTrackPart,
    .BackButtonEndPart, .ForwardButtonEndPart, .ScrollbarBGPart, .TrackBGPart,
  ]
}

enum ScrollbarButtonsPlacement {
  case ScrollbarButtonsNone
  case ScrollbarButtonsSingle
  case ScrollbarButtonsDoubleStart
  case ScrollbarButtonsDoubleEnd
  case ScrollbarButtonsDoubleBoth
}

enum ScrollPositioningBehavior {
  case None
  case Moves
  case Stationary
}
