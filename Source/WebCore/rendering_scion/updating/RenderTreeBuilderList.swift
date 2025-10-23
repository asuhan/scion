/**
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2006, 2010, 2017 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Andrew Wellington (proton@wiretapped.net)
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

private func getParentOfFirstLineBox(current: RenderBlockWrapper, marker: RenderObjectWrapper)
  -> RenderBlockWrapper?
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func firstNonMarkerChild(parent: RenderBlockWrapper) -> RenderObjectWrapper? {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

extension RenderTreeBuilder {
  class List {
    init(builder: RenderTreeBuilder) {
      self.builder = builder
    }

    func updateItemMarker(listItemRenderer: RenderListItemWrapper) {
      let style = listItemRenderer.style()

      if style.listStyleType().type == .None
        && (style.listStyleImage() == nil || style.listStyleImage()!.errorOccurred())
      {
        if let marker = listItemRenderer.markerRenderer() {
          builder.destroy(renderer: marker)
        }
        return
      }

      let newStyle = listItemRenderer.computeMarkerStyle()
      var markerRenderer = listItemRenderer.markerRenderer()
      if markerRenderer == nil {
        markerRenderer!.setStyle(style: newStyle)
      } else {
        markerRenderer = CreateRenderer.RenderListMarker(
          listItem: listItemRenderer, style: newStyle)
        markerRenderer!.initializeStyle()
        listItemRenderer.setMarkerRenderer(marker: markerRenderer!)
      }

      let currentParent = markerRenderer!.parent()
      var newParent = getParentOfFirstLineBox(current: listItemRenderer, marker: markerRenderer!)
      if newParent == nil {
        // If the marker is currently contained inside an anonymous box,
        // then we are the only item in that anonymous box (since no line box
        // parent was found). It's ok to just leave the marker where it is
        // in this case.
        if currentParent != nil && currentParent!.isAnonymousBlock() {
          return
        }
        if let multiColumnFlow = listItemRenderer.multiColumnFlowForBlockFlow() {
          newParent = multiColumnFlow
        } else {
          newParent = listItemRenderer
        }
      }

      if CPtrToInt(newParent?.p) == CPtrToInt(currentParent?.p) {
        return
      }

      if currentParent != nil {
        builder.attach(
          parent: newParent!,
          child: builder.detach(
            parent: currentParent!, child: markerRenderer!, willBeDestroyed: .No,
            canCollapseAnonymousBlock: .No)!, beforeChild: firstNonMarkerChild(parent: newParent!))
      } else {
        builder.attach(
          parent: newParent!, child: markerRenderer!,
          beforeChild: firstNonMarkerChild(parent: newParent!))
      }

      // If current parent is an anonymous block that has lost all its children, destroy it.
      if currentParent != nil && currentParent!.isAnonymousBlock()
        && currentParent!.firstChild() == nil
        && (currentParent as! RenderBlockFlowWrapper).continuation() == nil
      {
        builder.destroy(renderer: currentParent!)
      }
    }

    private let builder: RenderTreeBuilder
  }
}
