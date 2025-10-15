/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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

private func supportsFirstLetter(block: RenderBlockWrapper) -> Bool {
  if block is RenderButtonWrapper {
    return true
  }
  if !(block is RenderBlockFlowWrapper) {
    return false
  }
  if block is RenderSVGTextWrapper {
    return false
  }
  return block.canHaveGeneratedChildren()
}

extension RenderTreeBuilder {
  class FirstLetter {
    func updateAfterDescendants(block: RenderBlockWrapper) {
      if !block.style().hasPseudoStyle(pseudo: .FirstLetter) {
        return
      }
      if !supportsFirstLetter(block: block) {
        return
      }

      // FIXME: This should be refactored, firstLetterContainer is not needed.
      let renderObjects = block.getFirstLetter()
      let firstLetterRenderer = renderObjects.firstLetter
      let firstLetterContainer = renderObjects.firstLetterContainer

      if firstLetterRenderer == nil {
        return
      }

      // Other containers are handled when updating their renderers.
      if CPtrToInt(block.p) == CPtrToInt(firstLetterContainer?.p) {
        return
      }

      // If the child already has style, then it has already been created, so we just want
      // to update it.
      if firstLetterRenderer!.parent()!.style().pseudoElementType() == .FirstLetter {
        updateStyle(firstLetterBlock: block, currentChild: firstLetterRenderer!)
        return
      }

      if let renderText = firstLetterRenderer as? RenderTextWrapper {
        createRenderers(currentTextChild: renderText)
      }
    }

    private func updateStyle(
      firstLetterBlock: RenderBlockWrapper, currentChild: RenderObjectWrapper
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func createRenderers(currentTextChild: RenderTextWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }
}
