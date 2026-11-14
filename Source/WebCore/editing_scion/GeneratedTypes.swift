import wk_interop

struct CString {
  init(_ arg0: CChar?) {
    fatalError("Not implemented")
  }
  init(_ arg0: [CChar]) {
    fatalError("Not implemented")
  }
  init(_ arg0: [UInt8]) {
    fatalError("Not implemented")
  }
  init(characters: [UInt8]) {
    fatalError("Not implemented")
  }
  func data() -> CChar? {
    fatalError("Not implemented")
  }
}

struct ExceptionOr {
}

final class FrameDestructionObserver {
  init() {}
  init(_ arg0: LocalFrameWrapper?) {
    fatalError("Not implemented")
  }
  func frame() -> LocalFrameWrapper? {
    fatalError("Not implemented")
  }
}

class HTMLDListElementWrapper: HTMLElementWrapper {}

class HTMLLIElementWrapper: HTMLElementWrapper {}

class HTMLParagraphElementWrapper: HTMLElementWrapper {}

class HTMLPictureElementWrapper: HTMLElementWrapper {}

class HTMLProgressElementWrapper: HTMLElementWrapper {}

class HTMLSpanElementWrapper: HTMLElementWrapper {}

struct HashTable {
}

struct HashTableAddResult {
}

struct HashTableIterator {
}

struct IntersectingNodeRangeWithQuirk {
  init(_ arg0: SimpleRange) {
    fatalError("Not implemented")
  }
}

struct LazyNeverDestroyed {
}

struct LocalCaretRect {
  var rect: LayoutRectWrapper = LayoutRectWrapper()
  var renderer: RenderObjectWrapper? = nil
}

struct PositionRange {
  var start: Position = Position()
  var end: Position = Position()
}

class TextPlaceholderElementWrapper: HTMLDivElementWrapper {}

struct Tree {
  init() {}
}

extension AXObjectCacheWrapper {
  func rootAXEditableElement(_ arg0: NodeWrapper?) -> ElementWrapper? {
    fatalError("Not implemented")
  }
}

extension IntPoint {
  func constrainedBetween(min: IntPoint, max: IntPoint) -> IntPoint {
    fatalError("Not implemented")
  }
}

extension TreeScopeWrapper {
  func ancestorNodeInThisScope(_ arg0: NodeWrapper?) -> NodeWrapper? {
    fatalError("Not implemented")
  }
}

extension VisibleSelectionWrapper {
  func visibleStart() -> VisiblePosition {
    fatalError("Not implemented")
  }
  func visibleEnd() -> VisiblePosition {
    fatalError("Not implemented")
  }
  func firstRange() -> SimpleRange? {
    fatalError("Not implemented")
  }
}
