/*
 * Copyright (C) 2004, 2005, 2006, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005 Rob Buis <buis@kde.org>
 * Copyright (C) 2005 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 * Copyright (C) 2021-2023 Apple Inc.  All rights reserved.
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

enum ComponentTransferType: UInt8 {
  case FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0
  case FECOMPONENTTRANSFER_TYPE_IDENTITY = 1
  case FECOMPONENTTRANSFER_TYPE_TABLE = 2
  case FECOMPONENTTRANSFER_TYPE_DISCRETE = 3
  case FECOMPONENTTRANSFER_TYPE_LINEAR = 4
  case FECOMPONENTTRANSFER_TYPE_GAMMA = 5
}

struct ComponentTransferFunction: Equatable {
  var type: ComponentTransferType = .FECOMPONENTTRANSFER_TYPE_UNKNOWN

  var slope: Float32 = 0
  var intercept: Float32 = 0
  let amplitude: Float32 = 0
  let exponent: Float32 = 0
  let offset: Float32 = 0

  let tableValues: [Float32] = []
}

class FEComponentTransferWrapper: FilterEffectWrapper {
  static func create(
    redFunction: ComponentTransferFunction, greenFunction: ComponentTransferFunction,
    blueFunction: ComponentTransferFunction, alphaFunction: ComponentTransferFunction,
    colorSpace: DestinationColorSpace = DestinationColorSpace.SRGB()
  ) -> FEComponentTransferWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
