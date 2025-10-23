/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2008, 2009, 2010 Apple Inc. All right reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2014 Apple Inc. All rights reserved.
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

struct BidiIsolatedRun {
  let object: RenderObjectWrapper
  let root: RenderElementWrapper
  let runToReplace: BidiRun
  let position: UInt32
}

// This class is used to RenderInline subtrees, stepping by character within the
// text children. LegacyInlineIterator will use next to find the next RenderText
// optionally notifying a BidiResolver every time it steps into/out of a RenderInline.
class LegacyInlineIterator {
  init(root: RenderElementWrapper?, o: RenderObjectWrapper?, p: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func increment(resolver: InlineBidiResolver? = nil) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func atEnd() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
