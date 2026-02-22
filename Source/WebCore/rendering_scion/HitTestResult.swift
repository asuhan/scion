/*
 * Copyright (C) 2006-2023 Apple Inc.
 * Copyright (C) 2014 Google Inc.
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

enum HitTestProgress {
  case Stop
  case Continue
}

struct HitTestResultWrapper {
  init(_ other: HitTestLocationWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setInnerNode(_ node: NodeWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func innerNonSharedNode() -> NodeWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func innerNode() -> NodeWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setInnerNonSharedNode(_ node: NodeWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setURLElement(_ n: ElementWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func URLElement() -> ElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setScrollbar(_ scrollbar: Scrollbar) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsOverWidget(_ isOverWidget: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Forwarded from HitTestLocation
  func isRectBasedTest() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addNodeToListBasedTestResult(
    node: NodeWrapper?, request: HitTestRequestWrapper, locationInContainer: HitTestLocationWrapper,
    rect: LayoutRectWrapper = LayoutRectWrapper()
  ) -> HitTestProgress {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func append(_ other: HitTestResultWrapper, _ request: HitTestRequestWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let hitTestLocation: HitTestLocationWrapper

  // A point in the local coordinate space of m_innerNonSharedNode's renderer. Allows us to efficiently
  // determine where inside the renderer we hit on subsequent operations.
  var localPoint: LayoutPointWrapper
}
