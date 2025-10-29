target_sources(layout_scion PRIVATE
    RenderSVGBlock.swift
    RenderSVGContainer.swift
    RenderSVGHiddenContainer.swift
    RenderSVGInline.swift
    RenderSVGModelObject.swift
    RenderSVGResourceClipper.swift
    RenderSVGResourceContainer.swift
    RenderSVGForeignObject.swift
    RenderSVGRoot.swift
    RenderSVGShape.swift
    RenderSVGText.swift
    RenderSVGViewportContainer.swift
    SVGTextLayoutAttributes.swift
)
add_subdirectory(legacy)
