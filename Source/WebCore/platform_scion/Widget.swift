/*
 * Copyright (C) 2004-2018 Apple Inc.  All rights reserved.
 * Copyright (C) 2008 Collabora Ltd.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// The Widget class serves as a base class for three kinds of objects:
// (1) Scrollable areas (ScrollView)
// (2) Scrollbars (Scrollbar)
// (3) Plugins (PluginView)
//
// A widget may or may not be backed by a platform-specific object (e.g., HWND on Windows, NSView on Mac, QWidget on Qt).
//
// Widgets are connected in a hierarchy, with the restriction that plugins and scrollbars are always leaves of the
// tree.  Only ScrollViews can have children (and therefore the Widget class has no concept of children).
//
// The rules right now for which widgets get platform-specific objects are as follows:
// ScrollView - Mac
// Scrollbar - Mac, Gtk
// Plugin - Mac, Windows (windowed only), Qt (windowed only, widget is an HWND on windows), Gtk (windowed only)
//

typealias PlatformWidget = UnsafeMutableRawPointer?

protocol Widget {
  func platformWidget() -> PlatformWidget

  func width() -> Int32

  func height() -> Int32

  func size() -> IntSize
}
