//
//  ContentZoomGeometry.swift
//  FlowVision
//
//  Pure geometry for zoom / pan / fit of large-view content (image or video surface).
//

import Foundation
import CoreGraphics

/// Letterbox (contain) `aspectRatio` inside `bounds`, centered — same spirit as `AVMakeRect`.
func fitContentRect(aspectRatio: CGSize, insideRect bounds: CGRect) -> CGRect {
    let aw = max(aspectRatio.width, 0.0001)
    let ah = max(aspectRatio.height, 0.0001)
    let bw = max(bounds.width, 0.0001)
    let bh = max(bounds.height, 0.0001)
    let scale = min(bw / aw, bh / ah)
    let w = aw * scale
    let h = ah * scale
    let x = bounds.origin.x + (bw - w) / 2
    let y = bounds.origin.y + (bh - h) / 2
    return CGRect(x: x, y: y, width: w, height: h)
}

/// Scale `frame` by `factor` keeping the content-space anchor under the same view point.
/// `anchorInContent` is in the content view's local coordinates (0…frame.size).
func applyRelativeZoom(frame: CGRect, factor: CGFloat, anchorInContent: CGPoint) -> CGRect {
    let f = max(factor, 0.0001)
    let newW = frame.width * f
    let newH = frame.height * f
    let ax = frame.width > 0 ? anchorInContent.x / frame.width : 0.5
    let ay = frame.height > 0 ? anchorInContent.y / frame.height : 0.5
    let newX = frame.origin.x - (newW - frame.width) * ax
    let newY = frame.origin.y - (newH - frame.height) * ay
    return CGRect(x: newX, y: newY, width: newW, height: newH)
}

/// Clamp frame origin so the rect still intersects `viewBounds` (cannot be dragged fully away).
func clampContentFrame(_ frame: CGRect, in viewBounds: CGRect) -> CGRect {
    var origin = frame.origin
    let size = frame.size
    // Same spirit as LargeImageView image pan clamp:
    // maxX < 0 → origin.x = -width; minX > viewW → origin.x = viewW; etc.
    if origin.x + size.width < 0 {
        origin.x = -size.width
    }
    if origin.x > viewBounds.width {
        origin.x = viewBounds.width
    }
    if origin.y + size.height < 0 {
        origin.y = -size.height
    }
    if origin.y > viewBounds.height {
        origin.y = viewBounds.height
    }
    return CGRect(origin: origin, size: size)
}

/// Translate frame by delta then clamp.
func panContentFrame(_ frame: CGRect, deltaX: CGFloat, deltaY: CGFloat, in viewBounds: CGRect) -> CGRect {
    var f = frame
    f.origin.x += deltaX
    f.origin.y += deltaY
    return clampContentFrame(f, in: viewBounds)
}

/// Absolute scale from a base size around a center point in content local coords.
func applyAbsoluteZoom(baseSize: CGSize, scale: CGFloat, centerPoint: CGPoint, currentFrame: CGRect) -> CGRect {
    let s = max(scale, 0.0001)
    let newW = baseSize.width * s
    let newH = baseSize.height * s
    let deltaW = newW - currentFrame.width
    let deltaH = newH - currentFrame.height
    let cx = currentFrame.width > 0 ? centerPoint.x / currentFrame.width : 0.5
    let cy = currentFrame.height > 0 ? centerPoint.y / currentFrame.height : 0.5
    let newX = currentFrame.origin.x - deltaW * cx
    let newY = currentFrame.origin.y - deltaH * cy
    return CGRect(x: newX, y: newY, width: newW, height: newH)
}
