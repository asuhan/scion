/*
 * Copyright (C) 1998, 1999 Torben Weis <weis@kde.org>
 *                     1999-2001 Lars Knoll <knoll@kde.org>
 *                     1999-2001 Antti Koivisto <koivisto@kde.org>
 *                     2000-2001 Simon Hausmann <hausmann@kde.org>
 *                     2000-2001 Dirk Mueller <mueller@kde.org>
 *                     2000 Stefan Schimanski <1Stein@gmx.de>
 * Copyright (C) 2004-2018 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2008 Eric Seidel <eric@webkit.org>
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

final class LocalFrameWrapper: FrameWrapper {
  func document() -> Document? {
    guard let raw = wk_interop.LocalFrame_document(p) else { return nil }
    return Document(raw)
  }

  func view() -> LocalFrameViewWrapper? {
    guard let raw = wk_interop.LocalFrame_view(p) else { return nil }
    return LocalFrameViewWrapper(raw)
  }

  func editor() -> EditorWrapper { return EditorWrapper(wk_interop.LocalFrame_editor(p)) }

  func eventHandler() -> EventHandler { return EventHandler(wk_interop.LocalFrame_eventHandler(p)) }

  // TODO(asuhan): remove this, it's not needed in Swift
  func checkedEventHandler() -> EventHandler { return eventHandler() }

  func selection() -> FrameSelectionWrapper {
    return FrameSelectionWrapper(wk_interop.LocalFrame_selection(p))
  }

  func rootFrame() -> LocalFrameWrapper {
    return LocalFrameWrapper(wk_interop.LocalFrame_rootFrame(p))
  }

  func contentRenderer() -> RenderViewWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldUsePrintingLayout() -> Bool {
    return wk_interop.LocalFrame_shouldUsePrintingLayout(p)
  }

  // Scale factor of this frame with respect to the container.
  func frameScaleFactor() -> Float32 { return wk_interop.LocalFrame_frameScaleFactor(p) }
}
