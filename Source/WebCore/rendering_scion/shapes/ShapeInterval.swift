/*
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

class ShapeInterval<T: Numeric & Comparable> {
  init(_ x1: T, _ x2: T) {
    m_x1 = x1
    m_x2 = x2
    assert(x2 >= x1)
  }

  private func isUndefined() -> Bool { return m_x2 < m_x1 }
  func x1() -> T { return isUndefined() ? (0 as! T) : m_x1 }
  func x2() -> T { return isUndefined() ? (0 as! T) : m_x2 }
  func width() -> T { return isUndefined() ? (0 as! T) : m_x2 - m_x1 }
  func isEmpty() -> Bool { return isUndefined() ? true : m_x1 == m_x2 }

  private func set_(_ x1: T, _ x2: T) {
    assert(x2 >= x1)
    m_x1 = x1
    m_x2 = x2
  }

  func unite(_ interval: ShapeInterval<T>) {
    if interval.isUndefined() {
      return
    }
    if isUndefined() {
      set_(interval.x1(), interval.x2())
    } else {
      set_(min(x1(), interval.x1()), max(x2(), interval.x2()))
    }
  }

  private var m_x1: T
  private var m_x2: T
}

typealias IntShapeInterval = ShapeInterval<Int32>
