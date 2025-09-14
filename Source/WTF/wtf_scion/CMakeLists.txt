target_sources(layout_scion PRIVATE
    ASCIICType.swift
    GenericTimeMixin.swift
    IteratorRange.swift
    ListSet.swift
    MathExtras.swift
    MonotonicTime.swift
    PriorityQueue.swift
    SaturatedArithmetic.swift
)
add_subdirectory(text)
add_subdirectory(unicode)
