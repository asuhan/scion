/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 *           (C) 2004 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

class LayoutRepainter {
  enum CheckForRepaint {
    case No
    case Yes
  }

  enum ShouldAlwaysIssueFullRepaint {
    case No
    case Yes
  }

  init(
    renderer: RenderElementWrapper, checkForRepaintOverride: CheckForRepaint? = nil,
    shouldAlwaysIssueFullRepaint: ShouldAlwaysIssueFullRepaint? = nil,
    repaintOutlineBounds: RepaintOutlineBounds = .Yes
  ) {
    self.renderer = renderer
    self.checkForRepaint =
      checkForRepaintOverride != nil
      ? checkForRepaintOverride! == .Yes : renderer.checkForRepaintDuringLayout()
    self.forceFullRepaint =
      shouldAlwaysIssueFullRepaint != nil && shouldAlwaysIssueFullRepaint! == .Yes
    self.repaintOutlineBounds = repaintOutlineBounds
    if !self.checkForRepaint {
      self.repaintContainer = nil
      self.oldRects = RenderObjectWrapper.RepaintRects()
      return
    }

    self.repaintContainer = self.renderer.containerForRepaint().renderer
    self.oldRects = self.renderer.rectsForRepaintingAfterLayout(
      repaintContainer, repaintOutlineBounds)
  }

  // Return true if it repainted.
  @discardableResult
  func repaintAfterLayout() -> Bool {
    if !checkForRepaint {
      return false
    }

    let requiresFullRepaint: RequiresFullRepaint =
      forceFullRepaint || renderer.selfNeedsLayout() ? .Yes : .No
    // Outline bounds are not used if we're doing a full repaint.
    let newRects = renderer.rectsForRepaintingAfterLayout(
      repaintContainer, (requiresFullRepaint == .Yes) ? .No : repaintOutlineBounds)
    return renderer.repaintAfterLayoutIfNeeded(
      repaintContainer, requiresFullRepaint, oldRects: oldRects, newRects: newRects)
  }

  private let renderer: RenderElementWrapper
  private let repaintContainer: RenderLayerModelObjectWrapper?
  // We store these values as LayoutRects, but the final invalidations will be pixel snapped
  private let oldRects: RenderObjectWrapper.RepaintRects
  private let checkForRepaint: Bool
  private let forceFullRepaint: Bool
  private let repaintOutlineBounds: RepaintOutlineBounds
}
