/*
 * Copyright (C) 2006-2020 Apple Inc. All rights reserved.
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

class DocumentMarker {
  struct `Type`: OptionSet {
    let rawValue: UInt32

    static let Spelling = `Type`(rawValue: 1 << 0)
    static let Grammar = `Type`(rawValue: 1 << 1)
    static let TextMatch = `Type`(rawValue: 1 << 2)
    // Text has been modified by spell correction, reversion of spell correction or other type of substitution.
    // On some platforms, this prevents the text from being autocorrected again. On post Snow Leopard Mac OS X,
    // if a Replacement marker contains non-empty description, a reversion UI will be shown.
    static let Replacement = `Type`(rawValue: 1 << 3)
    // Renderer needs to add underline indicating that the text has been modified by spell
    // correction. Text with Replacement marker doesn't necessarily has CorrectionIndicator
    // marker. For instance, after some text has been corrected, it will have both Replacement
    // and CorrectionIndicator. However, if user further modifies such text, we would remove
    // CorrectionIndicator marker, but retain Replacement marker.
    static let CorrectionIndicator = `Type`(rawValue: 1 << 4)
    // Correction suggestion has been offered, but got rejected by user.
    static let RejectedCorrection = `Type`(rawValue: 1 << 5)
    // Text has been modified by autocorrection. The description of this marker is the original text before autocorrection.
    static let Autocorrected = `Type`(rawValue: 1 << 6)
    // On some platforms, this prevents the text from being spellchecked again.
    static let SpellCheckingExemption = `Type`(rawValue: 1 << 7)
    // This marker indicates user has deleted an autocorrection starting at the end of the
    // range that bears this marker. In some platforms, if the user later inserts the same original
    // word again at this position, it will not be autocorrected again. The description of this
    // marker is the original word before autocorrection was applied.
    static let DeletedAutocorrection = `Type`(rawValue: 1 << 8)
    // This marker indicates that the range of text spanned by the marker is entered by voice dictation,
    // and it has alternative text.
    static let DictationAlternatives = `Type`(rawValue: 1 << 9)
    // This marker indicates that the user has selected a text candidate.
    static let AcceptedCandidate = `Type`(rawValue: 1 << 13)
    // This marker indicates that the user has initiated a drag with this content.
    static let DraggedContent = `Type`(rawValue: 1 << 14)
    static let TransparentContent = `Type`(rawValue: 1 << 17)
  }

  static let allMarkers: `Type` = [
    .AcceptedCandidate,
    .Autocorrected,
    .CorrectionIndicator,
    .DeletedAutocorrection,
    .DictationAlternatives,
    .DraggedContent,
    .Grammar,
    .RejectedCorrection,
    .Replacement,
    .SpellCheckingExemption,
    .Spelling,
    .TextMatch,
    .TransparentContent,
  ]

  struct TransparentContentData {
    let node: NodeWrapper
  }

  enum Data {
    case Node(NodeWrapper)
    case TransparentContentData(TransparentContentData)
  }

  func startOffset() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func endOffset() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var type: `Type` {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var data: Data {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
