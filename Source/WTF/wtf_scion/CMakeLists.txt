target_sources(layout_scion PRIVATE
    ASCIICType.swift
    GenericTimeMixin.swift
    IteratorRange.swift
    ListSet.swift
    MathExtras.swift
    MonotonicTime.swift
    ObjectIdentifierHashSet.swift
    OptionalComparison.swift
    PriorityQueue.swift
    SaturatedArithmetic.swift
    WeakNullableRef.swift
)
add_subdirectory(text)
add_subdirectory(unicode)
