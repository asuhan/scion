/*
 * Copyright (C) 2011-2024 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

class FilterOperations: Sequence, IteratorProtocol, Equatable, CustomStringConvertible {
  init(_ p: UnsafeRawPointer) {
    self.p = p
    self.owner = false
  }

  init() {
    self.p = wk_interop.FilterOperations_create()
    self.owner = true
  }

  deinit {
    if owner {
      wk_interop.FilterOperations_destroy(p)
    }
  }

  static func == (lhs: FilterOperations, rhs: FilterOperations) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func next() -> FilterOperationWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func size() -> UInt64 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func at(_ index: UInt64) -> FilterOperationWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasFilterThatAffectsOpacity() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasFilterThatMovesPixels() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasFilterThatShouldBeRestrictedBySecurityOrigin() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasReferenceFilter() -> Bool { return wk_interop.FilterOperations_hasReferenceFilter(p) }

  func isReferenceFilter() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func transformColor(color: ColorWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  public var description: String {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let p: UnsafeRawPointer
  private let owner: Bool
}
