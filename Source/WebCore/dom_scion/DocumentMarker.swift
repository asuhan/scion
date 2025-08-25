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
  enum `Type`: UInt32 {
    case Spelling = 1
    case Grammar = 2
    case TextMatch = 4
    // Text has been modified by spell correction, reversion of spell correction or other type of substitution.
    // On some platforms, this prevents the text from being autocorrected again. On post Snow Leopard Mac OS X,
    // if a Replacement marker contains non-empty description, a reversion UI will be shown.
    case Replacement = 8
    // Renderer needs to add underline indicating that the text has been modified by spell
    // correction. Text with Replacement marker doesn't necessarily has CorrectionIndicator
    // marker. For instance, after some text has been corrected, it will have both Replacement
    // and CorrectionIndicator. However, if user further modifies such text, we would remove
    // CorrectionIndicator marker, but retain Replacement marker.
    case CorrectionIndicator = 16
    // Correction suggestion has been offered, but got rejected by user.
    case RejectedCorrection = 32
    // Text has been modified by autocorrection. The description of this marker is the original text before autocorrection.
    case Autocorrected = 64
    // On some platforms, this prevents the text from being spellchecked again.
    case SpellCheckingExemption = 128
    // This marker indicates user has deleted an autocorrection starting at the end of the
    // range that bears this marker. In some platforms, if the user later inserts the same original
    // word again at this position, it will not be autocorrected again. The description of this
    // marker is the original word before autocorrection was applied.
    case DeletedAutocorrection = 256
    // This marker indicates that the range of text spanned by the marker is entered by voice dictation,
    // and it has alternative text.
    case DictationAlternatives = 512
    // This marker indicates that the user has selected a text candidate.
    case AcceptedCandidate = 8192
    // This marker indicates that the user has initiated a drag with this content.
    case DraggedContent = 16384
    case TransparentContent = 131072
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
}
