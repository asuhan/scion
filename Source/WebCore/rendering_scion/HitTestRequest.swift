/*
 * Copyright (C) 2006 Apple Inc.
 * Copyright (C) 2009 Torch Mobile Inc. http://www.torchmobile.com/
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
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

struct HitTestRequestWrapper {
  struct `Type`: OptionSet {
    let rawValue: UInt32
    static let ReadOnly = Type(rawValue: 1 << 0)
    static let Active = Type(rawValue: 1 << 1)
    static let Move = Type(rawValue: 1 << 2)
    static let Release = Type(rawValue: 1 << 3)
    static let IgnoreCSSPointerEventsProperty = Type(rawValue: 1 << 4)
    static let IgnoreClipping = Type(rawValue: 1 << 5)
    static let SVGClipContent = Type(rawValue: 1 << 6)
    static let TouchEvent = Type(rawValue: 1 << 7)
    static let DisallowUserAgentShadowContent = Type(rawValue: 1 << 8)
    static let DisallowUserAgentShadowContentExceptForImageOverlays = Type(
      rawValue: 1 << 9)
    static let AllowFrameScrollbars = Type(rawValue: 1 << 10)
    static let AllowChildFrameContent = Type(rawValue: 1 << 11)
    static let AllowVisibleChildFrameContentOnly = Type(rawValue: 1 << 12)
    static let ChildFrameHitTest = Type(rawValue: 1 << 13)
    static let AccessibilityHitTest = Type(rawValue: 1 << 14)
    // Collect a list of nodes instead of just one. Used for elementsFromPoint and rect-based tests.
    static let CollectMultipleElements = Type(rawValue: 1 << 15)
    // When using list-based testing, continue hit testing even after a hit has been found.
    static let IncludeAllElementsUnderPoint = Type(rawValue: 1 << 16)
    static let PenEvent = Type(rawValue: 1 << 17)
  }

  static let defaultTypes = `Type`([.ReadOnly, .Active, .DisallowUserAgentShadowContent])

  // FIXME: This constructor should be phased out in favor of the `HitTestSource` version above, such that all call sites must
  // consider whether the hit test request is user-triggered or bindings-triggered.
  init(type: `Type` = defaultTypes) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func active() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func release() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func ignoreClipping() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgClipContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func allowsChildFrameContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func allowsVisibleChildFrameContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isChildFrameHitTest() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func resultIsElementList() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func userTriggered() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let type: `Type`
}
