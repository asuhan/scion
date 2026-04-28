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
  struct Type_: OptionSet {
    let rawValue: UInt32
    static let ReadOnly = Type_(rawValue: 1 << 0)
    static let Active = Type_(rawValue: 1 << 1)
    static let Move = Type_(rawValue: 1 << 2)
    static let Release = Type_(rawValue: 1 << 3)
    static let IgnoreCSSPointerEventsProperty = Type_(rawValue: 1 << 4)
    static let IgnoreClipping = Type_(rawValue: 1 << 5)
    static let SVGClipContent = Type_(rawValue: 1 << 6)
    static let TouchEvent = Type_(rawValue: 1 << 7)
    static let DisallowUserAgentShadowContent = Type_(rawValue: 1 << 8)
    static let DisallowUserAgentShadowContentExceptForImageOverlays = Type_(
      rawValue: 1 << 9)
    static let AllowFrameScrollbars = Type_(rawValue: 1 << 10)
    static let AllowChildFrameContent = Type_(rawValue: 1 << 11)
    static let AllowVisibleChildFrameContentOnly = Type_(rawValue: 1 << 12)
    static let ChildFrameHitTest = Type_(rawValue: 1 << 13)
    static let AccessibilityHitTest = Type_(rawValue: 1 << 14)
    // Collect a list of nodes instead of just one. Used for elementsFromPoint and rect-based tests.
    static let CollectMultipleElements = Type_(rawValue: 1 << 15)
    // When using list-based testing, continue hit testing even after a hit has been found.
    static let IncludeAllElementsUnderPoint = Type_(rawValue: 1 << 16)
    static let PenEvent = Type_(rawValue: 1 << 17)
  }

  static let defaultTypes = Type_([.ReadOnly, .Active, .DisallowUserAgentShadowContent])

  init(_ source: HitTestSource, _ type: Type_ = defaultTypes) {
    // TODO(asuhan): add type consistency check.
    self.type = type
    self.source = source
  }

  // FIXME: This constructor should be phased out in favor of the `HitTestSource` version above, such that all call sites must
  // consider whether the hit test request is user-triggered or bindings-triggered.
  init(type: Type_ = defaultTypes) {
    // TODO(asuhan): add type consistency check.
    self.type = type
    self.source = .User
  }

  func active() -> Bool { return type.contains(.Active) }

  func release() -> Bool { return type.contains(.Release) }

  func ignoreCSSPointerEventsProperty() -> Bool {
    return type.contains(.IgnoreCSSPointerEventsProperty)
  }

  func ignoreClipping() -> Bool { return type.contains(.IgnoreClipping) }

  func svgClipContent() -> Bool { return type.contains(.SVGClipContent) }

  func allowsChildFrameContent() -> Bool { return type.contains(.AllowChildFrameContent) }

  func allowsVisibleChildFrameContent() -> Bool {
    return type.contains(.AllowVisibleChildFrameContentOnly)
  }

  func isChildFrameHitTest() -> Bool { return type.contains(.ChildFrameHitTest) }

  func resultIsElementList() -> Bool { return type.contains(.CollectMultipleElements) }

  func userTriggered() -> Bool { return source == .User }

  let type: Type_
  private let source: HitTestSource
}
