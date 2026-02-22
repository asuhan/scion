/*
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2023 Apple Inc. All rights reserved.
 *           (C) 2006 Alexey Proskuryakov (ap@nypop.com)
 * Copyright (C) 2010-2022 Google Inc. All rights reserved.
 * Copyright (C) 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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

// TODO(asuhan): add TypeAheadDataSource protocol and have this implement it
class HTMLSelectElementWrapper: HTMLFormControlElementWrapper {
  func size() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func listItems() -> ArraySlice<HTMLElementWrapper?> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func activeSelectionStartListIndex() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func activeSelectionEndListIndex() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setActiveSelectionEndIndex(_ index: Int32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func allowsNonContiguousSelection() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
