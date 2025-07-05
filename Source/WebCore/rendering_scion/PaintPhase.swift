/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 *           (C) 2004 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

/*
 *  The painting of a layer occurs in three distinct phases.  Each phase involves
 *  a recursive descent into the layer's render objects. The first phase is the background phase.
 *  The backgrounds and borders of all blocks are painted.  Inlines are not painted at all.
 *  Floats must paint above block backgrounds but entirely below inline content that can overlap them.
 *  In the foreground phase, all inlines are fully painted.  Inline replaced elements will get all
 *  three phases invoked on them during this phase.
 */

enum PaintPhase: UInt16 {
  case BlockBackground = 0
  case ChildBlockBackground = 1
  case ChildBlockBackgrounds = 2
  case Float = 4
  case Foreground = 8
  case Outline = 16
  case ChildOutlines = 32
  case SelfOutline = 64
  case Selection = 128
  case CollapsedTableBorders = 256
  case TextClip = 512
  case Mask = 1024
  case ClippingMask = 2048
  case EventRegion = 4096
  case Accessibility = 8192
}

struct PaintBehavior: OptionSet {
  let rawValue: UInt32
  static let Normal: PaintBehavior = []
  static let SelectionOnly = PaintBehavior(rawValue: 1)
  static let SkipSelectionHighlight = PaintBehavior(rawValue: 2)
  static let ForceBlackText = PaintBehavior(rawValue: 4)
  static let ForceWhiteText = PaintBehavior(rawValue: 8)
  static let ForceBlackBorder = PaintBehavior(rawValue: 16)
  static let RenderingSVGClipOrMask = PaintBehavior(rawValue: 32)
  static let SkipRootBackground = PaintBehavior(rawValue: 64)
  static let RootBackgroundOnly = PaintBehavior(rawValue: 128)
  static let SelectionAndBackgroundsOnly = PaintBehavior(rawValue: 256)
  static let ExcludeSelection = PaintBehavior(rawValue: 512)
  static let FlattenCompositingLayers = PaintBehavior(rawValue: 1024)  // Paint doesn't stop at compositing layer boundaries.
  static let ForceSynchronousImageDecode = PaintBehavior(rawValue: 2048)  // Paint should always complete image decoding of painted images.
  static let DefaultAsynchronousImageDecode = PaintBehavior(rawValue: 4096)  // Paint should always start asynchronous image decode of painted images, unless otherwise specified.
  static let CompositedOverflowScrollContent = PaintBehavior(rawValue: 8192)
  static let AnnotateLinks = PaintBehavior(rawValue: 16384)  // Collect all renderers with links to annotate their URLs (e.g. PDFs)
  static let EventRegionIncludeForeground = PaintBehavior(rawValue: 32768)  // FIXME: Event region painting should use paint phases.
  static let EventRegionIncludeBackground = PaintBehavior(rawValue: 65536)
  static let Snapshotting = PaintBehavior(rawValue: 131072)  // Paint is updating external backing store and visits all content, including composited content and always completes image decoding of painted images. FIXME: Will be removed.
  static let DontShowVisitedLinks = PaintBehavior(rawValue: 262144)
  static let ExcludeReplacedContent = PaintBehavior(rawValue: 524288)
}
