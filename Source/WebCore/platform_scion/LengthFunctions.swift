/*
    Copyright (C) 1999 Lars Knoll (knoll@kde.org)
    Copyright (C) 2006-2017 Apple Inc. All rights reserved.
    Copyright (C) 2011 Rik Cabanier (cabanier@adobe.com)
    Copyright (C) 2011 Adobe Systems Incorporated. All rights reserved.
    Copyright (C) 2012 Motorola Mobility, Inc. All rights reserved.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

// FIXME: when subpixel layout is supported this copy of floatValueForLength() can be removed. See bug 71143.
func floatValueForLength(length: LengthWrapper, maximumValue: LayoutUnit) -> Float32 {
  switch length.type() {
  case .Fixed:
    return length.value()
  case .Percent:
    return maximumValue * length.percent() / 100.0
  case .FillAvailable, .Auto, .Normal:
    return maximumValue.float()
  case .Calculated:
    return length.nonNanCalculatedValue(maxValue: maximumValue.float())
  case .Relative, .Intrinsic, .MinIntrinsic, .Content, .MinContent, .MaxContent, .FitContent,
    .Undefined:
    fatalError("Not reached")
  }
}

func valueForLength<T>(length: LengthWrapper, maximumValue: T) -> LayoutUnit {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

internal func minimumValueForLength(length: LengthWrapper, maximumValue: LayoutUnit) -> LayoutUnit {
  switch length.type() {
  case .Fixed:
    return LayoutUnit(value: length.value())
  case .Percent:
    // Don't remove the extra cast to float. It is needed for rounding on 32-bit Intel machines that use the FPU stack.
    return LayoutUnit(value: Float32(maximumValue * length.percent() / 100))
  case .Calculated:
    return LayoutUnit(value: length.nonNanCalculatedValue(maxValue: maximumValue.float()))
  case .FillAvailable, .Auto, .Normal, .Content:
    return LayoutUnit(value: 0)
  case .Relative, .Intrinsic, .MinIntrinsic, .MinContent, .MaxContent, .FitContent, .Undefined:
    fatalError("Not reached")
  }
}

func minimumValueForLength(length: LengthWrapper, maximumValue: InlineLayoutUnit) -> LayoutUnit {
  return minimumValueForLength(length: length, maximumValue: LayoutUnit(value: maximumValue))
}
