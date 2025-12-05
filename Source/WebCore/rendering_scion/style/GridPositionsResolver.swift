/*
 * Copyright (C) 2014-2017 Igalia S.L.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

enum GridTrackSizingDirection {
  case ForColumns
  case ForRows
}

// Class with all the code related to grid items positions resolution.
class GridPositionsResolver {
  static func spanSizeForAutoPlacedItem(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func resolveGridPositionsFromStyle(
    gridContainer: RenderGridWrapper, gridItem: RenderBoxWrapper,
    direction: GridTrackSizingDirection
  ) -> GridSpan {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func explicitGridColumnCount(gridContainer: RenderGridWrapper) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func explicitGridRowCount(gridContainer: RenderGridWrapper) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
