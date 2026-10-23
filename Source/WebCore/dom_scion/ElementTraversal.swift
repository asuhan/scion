/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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

import wk_interop

enum ElementTraversal {
  static func nextIncludingPseudo(_ current: NodeWrapper, _ stayWithin: NodeWrapper? = nil)
    -> ElementWrapper?
  {
    guard let next = wk_interop.ElementTraversal_nextIncludingPseudo(current.p, stayWithin?.p)
    else { return nil }
    return ElementWrapper(p: next)
  }

  static func nextIncludingPseudoSkippingChildren(
    _ current: NodeWrapper, _ stayWithin: NodeWrapper? = nil
  ) -> ElementWrapper? {
    guard
      let next = wk_interop.ElementTraversal_nextIncludingPseudoSkippingChildren(
        current.p, stayWithin?.p)
    else { return nil }
    return ElementWrapper(p: next)
  }

  static func previousIncludingPseudo(_ current: NodeWrapper, _ stayWithin: NodeWrapper? = nil)
    -> ElementWrapper?
  {
    guard
      let previous = wk_interop.ElementTraversal_previousIncludingPseudo(current.p, stayWithin?.p)
    else { return nil }
    return ElementWrapper(p: previous)
  }
}
