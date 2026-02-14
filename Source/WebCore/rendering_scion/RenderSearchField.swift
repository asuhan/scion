/**
 * Copyright (C) 2006, 2007, 2009, 2010, 2015 Apple Inc. All rights reserved.
 *           (C) 2008 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
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

// TODO(asuhan): also inherit from PopupMenuClient
final class RenderSearchFieldWrapper: RenderTextControlSingleLineWrapper {
  override final func computeControlLogicalHeight(
    lineHeight: LayoutUnit, nonContentHeight: LayoutUnit
  )
    -> LayoutUnit
  {
    var lineHeight = lineHeight
    var nonContentHeight = nonContentHeight
    let resultsButton = resultsButtonElement()
    if let resultsRenderer = resultsButton?.renderBox() {
      resultsRenderer.updateLogicalHeight()
      nonContentHeight = max(
        nonContentHeight,
        resultsRenderer.borderAndPaddingLogicalHeight() + resultsRenderer.marginLogicalHeight())
      lineHeight = max(lineHeight, resultsRenderer.logicalHeight())
    }
    let cancelButton = cancelButtonElement()
    if let cancelRenderer = cancelButton?.renderBox() {
      cancelRenderer.updateLogicalHeight()
      nonContentHeight = max(
        nonContentHeight,
        cancelRenderer.borderAndPaddingLogicalHeight() + cancelRenderer.marginLogicalHeight())
      lineHeight = max(lineHeight, cancelRenderer.logicalHeight())
    }

    return lineHeight + nonContentHeight
  }

  private func resultsButtonElement() -> HTMLElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func cancelButtonElement() -> HTMLElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
