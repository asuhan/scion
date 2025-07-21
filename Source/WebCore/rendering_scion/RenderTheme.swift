/*
 * Copyright (C) 2005-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

struct RenderTheme {
  // This function is to be implemented in platform-specific theme implementations to hand back the
  // appropriate platform theme.
  static func singleton() -> RenderTheme {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func documentMarkerLineColor(renderer: RenderTextWrapper, mode: DocumentMarkerLineStyleMode)
    -> ColorWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
