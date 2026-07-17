//
//  InitialZoom.swift
//  FlowVision
//
//  Pure helpers for initial large-image display size (fit / actual / fill).
//

import Foundation
import CoreGraphics

/// Default large-image zoom when opening / resetting size.
enum InitialZoomMode: String, Codable, CaseIterable {
    /// Scale image to fit entirely inside the view (contain).
    case fit
    /// Prefer 100% (actual pixels); if larger than the view, fall back to fit.
    case actual
    /// Scale image to cover the entire view (may crop).
    case fill
    
    var displayName: String {
        switch self {
        case .fit: return NSLocalizedString("initial-zoom-fit", comment: "Fit to Window")
        case .actual: return NSLocalizedString("initial-zoom-actual", comment: "Actual Size (100%)")
        case .fill: return NSLocalizedString("initial-zoom-fill", comment: "Fill Window")
        }
    }
}

/// Compute the image frame size (in points) for large view.
/// - Parameters:
///   - originalSize: pixel size of the source (already rotation-adjusted).
///   - maxBounds: available large-view size in points.
///   - backingScale: screen scale factor (e.g. 2 for Retina).
///   - mode: fit / actual / fill.
///   - allowActualUpscaleClamp: when mode is `.actual` and image is larger than view, clamp to fit (default true).
func computeInitialLargeImageSize(
    originalSize: CGSize,
    maxBounds: CGSize,
    backingScale: CGFloat,
    mode: InitialZoomMode,
    allowActualUpscaleClamp: Bool = true
) -> CGSize {
    let scale = max(backingScale, 0.0001)
    let ow = max(originalSize.width, 1)
    let oh = max(originalSize.height, 1)
    let mw = max(maxBounds.width, 1)
    let mh = max(maxBounds.height, 1)
    
    // Fit (contain) size in points
    let fitSize: CGSize = {
        if oh / ow * mw > mh {
            return CGSize(width: ow / oh * mh, height: mh)
        } else {
            return CGSize(width: mw, height: oh / ow * mw)
        }
    }()
    
    // Actual (100%) size in points
    let actualSize = CGSize(width: ow / scale, height: oh / scale)
    
    switch mode {
    case .fit:
        return fitSize
    case .actual:
        // Prefer 100%; if larger than the view, fall back to fit (same as prior "actual size" behavior).
        if allowActualUpscaleClamp,
           actualSize.width > fitSize.width + 0.5 || actualSize.height > fitSize.height + 0.5 {
            return fitSize
        }
        return actualSize
    case .fill:
        // Cover: scale so the smaller dimension of the view is filled (image may overflow).
        let coverScale = max(mw / (ow / scale), mh / (oh / scale))
        return CGSize(width: (ow / scale) * coverScale, height: (oh / scale) * coverScale)
    }
}
