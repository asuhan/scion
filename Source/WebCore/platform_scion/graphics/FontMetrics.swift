/*
 * Copyright (C) Research In Motion Limited 2010-2011. All rights reserved.
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

class FontMetricsWrapper {
  init(p: UnsafeRawPointer?) {
    self.p = p
  }

  func height(_ baselineType: FontBaseline = .AlphabeticBaseline) -> Float32 {
    return ascent(baselineType: baselineType) + descent(baselineType)
  }

  func intHeight(baselineType: FontBaseline = .AlphabeticBaseline) -> Int {
    return Int(wk_interop.FontMetrics_intHeight(p!, baselineType.rawValue))
  }

  func ascent(baselineType: FontBaseline = .AlphabeticBaseline) -> Float32 {
    return wk_interop.FontMetrics_ascent(p!, baselineType.rawValue)
  }

  func intAscent(baselineType: FontBaseline = .AlphabeticBaseline) -> Int {
    return Int(wk_interop.FontMetrics_intAscent(p!, baselineType.rawValue))
  }

  func descent(_ baselineType: FontBaseline = .AlphabeticBaseline) -> Float32 {
    return wk_interop.FontMetrics_descent(p!, baselineType.rawValue)
  }

  func intDescent(baselineType: FontBaseline = .AlphabeticBaseline) -> Int {
    return Int(wk_interop.FontMetrics_intDescent(p!, baselineType.rawValue))
  }

  func lineSpacing() -> Float32 {
    return wk_interop.FontMetrics_lineSpacing(p!)
  }

  func intLineSpacing() -> Int {
    return Int(wk_interop.FontMetrics_intLineSpacing(p!))
  }

  func xHeight() -> Float32? {
    let xHeight = wk_interop.FontMetrics_xHeight(p!)
    if !xHeight.is_valid {
      return nil
    }
    return xHeight.value
  }

  func capHeight() -> Float32? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func intCapHeight() -> Int {
    return Int(wk_interop.FontMetrics_intCapHeight(p!))
  }

  // TODO(asuhan): use a Markable equivalent instead
  func underlineThickness() -> Float32? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasIdenticalAscentDescentAndLineGap(_ other: FontMetricsWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var p: UnsafeRawPointer?
}
