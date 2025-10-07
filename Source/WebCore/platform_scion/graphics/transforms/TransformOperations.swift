/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2008 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
 * Copyright (C) 1999 Antti Koivisto (koivisto@kde.org)
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

class TransformOperations: Equatable {
  init(operations: [TransformOperation]) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func == (a: TransformOperations, b: TransformOperations) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Return true if any of the operation types are 3D operation types (even if the
  // values describe affine transforms)
  func has3DOperation() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRepresentableIn2D() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
