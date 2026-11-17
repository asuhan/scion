/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2004-2020 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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
 *
 */

import wk_interop

class DocumentMarkerControllerWrapper {
  init(_ p: UnsafeMutableRawPointer) { self.p = p }

  func hasMarkers() -> Bool {
    return wk_interop.DocumentMarkerController_hasMarkers(p)
  }

  func markersFor(node: NodeWrapper, _ types: DocumentMarker.`Type` = DocumentMarker.allMarkers)
    -> [RenderedDocumentMarker]
  {
    var markers: [RenderedDocumentMarker] = []
    withUnsafeMutablePointer(to: &markers) { markersPointer in
      wk_interop.DocumentMarkerController_markersFor(p, node.p, types.rawValue, markersPointer) {
        markers, marker in
        markers!.assumingMemoryBound(to: [RenderedDocumentMarker].self).pointee.append(
          RenderedDocumentMarker(marker!))
      }
    }
    return markers
  }

  static func markerYPositionAndHeightForFont(font: FontCascadeWrapper) -> (Float32, Float32) {
    var y: Float32 = 0
    var height: Float32 = 0
    wk_interop.DocumentMarkerController_markerYPositionAndHeightForFont(font.p, &y, &height)
    return (y, height)
  }

  private let p: UnsafeMutableRawPointer
}
