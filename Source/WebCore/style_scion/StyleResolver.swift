/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004-2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2006, 2007 Nicholas Shanks (webkit@nickshanks.com)
 * Copyright (C) 2003-2019 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alexey Proskuryakov <ap@webkit.org>
 * Copyright (C) 2007, 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (c) 2011, Code Aurora Forum. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
 * Copyright (C) 2012, 2013 Google Inc. All rights reserved.
 * Copyright (C) 2014 Igalia S.L.
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

private func convertToStyleScrollbarStateRaw(_ s: StyleScrollbarState) -> StyleScrollbarStateRaw {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

extension Style {

  class Resolver {
    init(_ p: UnsafeMutableRawPointer) { self.p = p }

    func styleForPseudoElement(
      _ element: ElementWrapper, _ pseudoElementRequest: PseudoElementRequest,
      _ context: ResolutionContext
    ) -> ResolvedStyle? {
      let pseudoElementIdentifierRaw = PseudoElementIdentifierRaw(
        pseudoId: pseudoElementRequest.identifier().pseudoId.rawValue,
        nameArgument: pseudoElementRequest.identifier().nameArgument.p!)
      let pseudoElementRequestRaw = PseudoElementRequestRaw(
        identifier: pseudoElementIdentifierRaw,
        scrollbarState: pseudoElementRequest.scrollbarState() != nil
          ? OptionalStyleScrollbarStateRaw(
            value: convertToStyleScrollbarStateRaw(pseudoElementRequest.scrollbarState()!),
            is_valid: true)
          : OptionalStyleScrollbarStateRaw(value: StyleScrollbarStateRaw(), is_valid: false))
      wk_interop.Resolver_styleForPseudoElement(
        p, element.p, pseudoElementRequestRaw, context.parentStyle?.p)
      return nil
    }

    private let p: UnsafeMutableRawPointer
  }

  struct ResolutionContext {
    let parentStyle: RenderStyleWrapper?
  }

}
