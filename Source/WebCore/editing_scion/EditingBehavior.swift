/*
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2010 Apple Inc. All rights reserved.
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

import wk_interop

struct EditingBehavior {
  init(type: EditingBehaviorType) {
    self.type = type
  }

  func shouldMoveCaretToHorizontalBoundaryWhenPastTopOrBottom() -> Bool {
    return type != .Windows
  }

  func shouldConsiderSelectionAsDirectional() -> Bool {
    return type != .Mac && type != .iOS
  }

  func shouldCenterAlignWhenSelectionIsRevealed() -> Bool {
    return type == .Mac || type == .iOS
  }

  func shouldToggleStyleBasedOnStartOfSelection() -> Bool {
    return type == .Mac || type == .iOS
  }

  func shouldAlwaysGrowSelectionWhenExtendingToBoundary() -> Bool {
    return type == .Mac || type == .iOS
  }

  func shouldSelectOnContextualMenuClick() -> Bool {
    return type == .Mac
  }

  func shouldAllowSpellingSuggestionsWithoutSelection() -> Bool {
    return type == .Unix
  }

  func shouldNavigateBackOnBackspace() -> Bool {
    return type != .Unix
  }

  func shouldExtendSelectionByWordOrLineAcrossCaret() -> Bool {
    return type != .Mac && type != .iOS
  }

  func shouldSkipSpaceWhenMovingRight() -> Bool {
    return type == .Windows
  }

  func shouldRebalanceWhiteSpacesInSecureField() -> Bool {
    return type != .iOS
  }

  func shouldSelectBasedOnDictionaryLookup() -> Bool {
    return type == .Mac || type == .iOS
  }

  func shouldAlwaysExtendSelectionFromExtentEndpoint() -> Bool {
    return type != .Mac && type != .iOS
  }

  func shouldMoveSelectionToEndWhenFocusingTextInput() -> Bool {
    return type == .iOS
  }

  func shouldAlwaysSmartDelete() -> Bool {
    return type == .iOS
  }

  func shouldSmartInsertDeleteParagraphs() -> Bool {
    return type == .iOS
  }

  private var type: EditingBehaviorType
}
