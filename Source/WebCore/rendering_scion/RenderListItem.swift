/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
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

import wk_interop

final class RenderListItemWrapper: RenderBlockFlowWrapper {
  init(_ element: ElementWrapper, _ style: RenderStyleWrapper) {
    super.init(type: .ListItem, element: element, style: style)
    assert(isRenderListItem())
    setInline(false)
  }

  override init(p: UnsafeMutableRawPointer) { super.init(p: p) }

  deinit {
    // Do not add any code here. Add it to willBeDestroyed() instead.
    assert(m_marker == nil)
  }

  func value() -> Int32 {
    assert(isNativeImpl())
    if m_value == nil {
      updateValueNow()
    }
    return m_value!
  }

  func updateValue() {
    assert(isNativeImpl())
    m_value = nil
    m_marker?.setNeedsLayoutAndPrefWidthsRecalc()
  }

  func updateListMarkerNumbers() {
    assert(isNativeImpl())
    guard let list = enclosingList(self) else {
      return
    }

    var isInReversedOrderedList = false
    if list.hasOLTagName() {
      let orderedList = HTMLOListElementWrapper(p: list.p)
      orderedList.itemCountChanged()
      isInReversedOrderedList = orderedList.isReversed()
    }

    // If an item has been marked for update before, we know that all following items have, too.
    // This gives us the opportunity to stop and avoid marking the same nodes again.
    let subsequentListItem = isInReversedOrderedList ? previousListItem : nextListItem
    var item: RenderListItemWrapper? = self
    while true {
      item = subsequentListItem(list, item!)
      guard let item, item.m_value != nil else {
        break
      }
      item.updateValue()
    }
  }

  func isInReversedOrderedList() -> Bool {
    assert(isNativeImpl())
    guard let list = enclosingList(self), list.hasOLTagName() else {
      return false
    }
    return HTMLOListElementWrapper(p: list.p).isReversed()
  }

  private func updateValueNow() {
    assert(isNativeImpl())
    let list = enclosingList(self)
    let orderedList = list.flatMap { $0.hasOLTagName() ? HTMLOListElementWrapper(p: $0.p) : nil }

    // The start item is either the closest item before this one in the list that already has a value,
    // or the first item in the list if none have before this have values yet.
    // FIXME: This should skip over items with counter-reset.
    var startItem = self
    if let list {
      var item: RenderListItemWrapper? = self
      while true {
        item = previousListItem(list, item!)
        guard let item else {
          break
        }
        startItem = item
        if item.m_value != nil {
          break
        }
      }
    }

    let defaultIncrement: Int32 = (orderedList?.isReversed() ?? false) ? -1 : 1
    let valueForItem = { (previousValue: Int32, directives: CounterDirectives) -> Int32 in
      if let setValue = directives.setValue {
        return setValue
      }
      let increment = directives.incrementValue ?? defaultIncrement
      if let resetValue = directives.resetValue {
        return resetValue &+ increment
      }
      return previousValue &+ increment
    }

    if startItem.m_value == nil {
      // Take in account enclosing list counter-reset.
      // FIXME: This can be a lot more simple when lists use presentational hints.
      if let list, let listRenderer = list.renderer() {
        let listDirectives = listRenderer.style().counterDirectives().map.get(listItemCounterName)
        if let resetValue = listDirectives.resetValue {
          startItem.m_value = resetValue
        } else {
          startItem.m_value = orderedList != nil ? orderedList!.start() &- defaultIncrement : 0
        }
      }
      let directives = startItem.style().counterDirectives().map.get(listItemCounterName)
      startItem.m_value = valueForItem(startItem.m_value ?? 0, directives)
    }

    var value = startItem.m_value!

    var item = startItem
    while item !== self {
      item = nextListItem(list!, item)!
      let directives = item.style().counterDirectives().map.get(listItemCounterName)
      item.m_value = valueForItem(value, directives)
      // counter-reset creates a new nested counter, so it should not be counted towards the current counter.
      if directives.resetValue == nil {
        value = item.m_value!
      }
    }
  }

  private func counterDirectivesChanged() {
    assert(isNativeImpl())
    m_marker?.setNeedsLayoutAndPrefWidthsRecalc()

    updateValue()
    guard let list = enclosingList(self) else {
      return
    }
    var item: RenderListItemWrapper? = self
    while true {
      item = nextListItem(list, item!)
      guard let item else {
        break
      }
      item.updateValue()
    }
  }

  func computeMarkerStyle() -> RenderStyleWrapper {
    assert(isNativeImpl())
    if !element()!.isPseudoElement() {
      if let markerStyle = getCachedPseudoStyle(
        pseudoElementIdentifier: Style.PseudoElementIdentifier(pseudoId: .Marker),
        parentStyle: style())
      {
        return RenderStyleWrapper.clone(style: markerStyle)
      }
    }

    // The marker always inherits from the list item, regardless of where it might end
    // up (e.g., in some deeply nested line box). See CSS3 spec.
    let markerStyle = RenderStyleWrapper.create()
    markerStyle.inheritFrom(inheritParent: style())

    // In the case of a ::before or ::after pseudo-element, we manually apply the properties
    // otherwise set in the user-agent stylesheet since we don't support ::before::marker or
    // ::after::marker. See bugs.webkit.org/b/218897.
    let fontDescription = style().fontDescription().deepCopy()
    fontDescription.setVariantNumericSpacing(.TabularNumbers)
    markerStyle.setFontDescription(description: fontDescription)
    markerStyle.fontCascade().update(fontSelector: document().fontSelector())
    markerStyle.setUnicodeBidi(v: .Isolate)
    markerStyle.setWhiteSpaceCollapse(.Preserve)
    markerStyle.setTextWrapMode(v: .NoWrap)
    markerStyle.setTextTransform([])
    return markerStyle
  }

  func markerRenderer() -> RenderListMarkerWrapper? {
    assert(isNativeImpl())
    return m_marker
  }

  func setMarkerRenderer(marker: RenderListMarkerWrapper) {
    assert(isNativeImpl())
    m_marker = marker
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(isNativeImpl())
    if !logicalHeight().bool() && hasNonVisibleOverflow() {
      return
    }

    super.paint(paintInfo: &paintInfo, paintOffset: paintOffset)
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    assert(isNativeImpl())
    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    if oldStyle == nil
      || oldStyle!.counterDirectives().map.get(listItemCounterName)
        == style().counterDirectives().map.get(listItemCounterName)
    {
      return
    }

    counterDirectivesChanged()
  }

  override func layout() {
    if !isNativeImpl() {
      wk_interop.RenderListItem_layout(id())
      return
    }
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    super.layout()
  }

  override final func computePreferredLogicalWidths() {
    assert(isNativeImpl())
    // FIXME: RenderListMarker::updateMargins() mutates margin style which affects preferred widths.
    if m_marker?.preferredLogicalWidthsDirty() ?? false {
      m_marker!.updateMarginsAndContent()
    }

    super.computePreferredLogicalWidths()
  }

  private var m_marker: RenderListMarkerWrapper?
  private var m_value: Int32? = nil
}

private let listItemCounterName = StringWrapper(ASCIILiteral("list-item"))

func isHTMLListElement(node: NodeWrapper) -> Bool {
  return node.hasULTagName() || node.hasOLTagName()
}

// Returns the enclosing list with respect to the DOM order.
private func enclosingList(_ listItem: RenderListItemWrapper) -> ElementWrapper? {
  let element = listItem.element()!
  let parent =
    element.isPseudoElement()
    ? PseudoElementWrapper(p: element.p).hostElement() : element.parentElement()
  var ancestor = parent
  while let current = ancestor {
    if isHTMLListElement(node: current)
      || ((current.renderer() as? RenderElementWrapper)?.shouldApplyStyleContainment() ?? false)
    {
      return current
    }
    ancestor = current.parentElement()
  }

  // If there's no actual list element, then the parent element acts as our
  // list for purposes of determining what other list items should be numbered as
  // part of the same list.
  return parent
}

private func nextListItemHelper(_ list: ElementWrapper, _ element: ElementWrapper)
  -> RenderListItemWrapper?
{
  var current: ElementWrapper? = element
  let advance = {
    if current!.renderOrDisplayContentsStyle() == nil {
      current = ElementTraversal.nextIncludingPseudoSkippingChildren(current!, list)
    } else {
      current = ElementTraversal.nextIncludingPseudo(current!, list)
    }
  }
  advance()
  while let element = current {
    guard let item = element.renderer() as? RenderListItemWrapper else {
      advance()
      continue
    }
    guard let otherList = enclosingList(item) else {
      advance()
      continue
    }

    // This item is part of our current list, so it's what we're looking for.
    if list.p == otherList.p {
      return item
    }

    // We found ourself inside another list; skip the rest of its contents.
    current = ElementTraversal.nextIncludingPseudoSkippingChildren(element, list)
  }

  return nil
}

private func nextListItem(_ list: ElementWrapper, _ item: RenderListItemWrapper)
  -> RenderListItemWrapper?
{
  return nextListItemHelper(list, item.element()!)
}

private func previousListItem(_ list: ElementWrapper, _ item: RenderListItemWrapper)
  -> RenderListItemWrapper?
{
  var current = item.element()
  let advance = {
    current = ElementTraversal.previousIncludingPseudo(current!, list)
  }
  advance()
  while let element = current {
    guard let item = element.renderer() as? RenderListItemWrapper else {
      advance()
      continue
    }
    guard let otherList = enclosingList(item) else {
      advance()
      continue
    }

    // This item is part of our current list, so we found what we're looking for.
    if list.p == otherList.p {
      return item
    }

    // We found ourself inside another list; skip the rest of its contents by
    // advancing to it. However, since the list itself might be a list item,
    // don't advance past it.
    current = otherList
  }
  return nil
}
