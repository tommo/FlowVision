//
//  ResampleFilter.swift
//  FlowVision
//
//  Pure resample-filter selection used by large-image resize paths.
//  Kept free of AppKit so it can be unit-checked without loading the app target.
//

import Foundation
import CoreGraphics

/// Resampling quality chosen for a single resize operation.
enum ResampleFilterKind: Equatable {
    /// Prior/default path behavior (CG `.high` / CI Lanczos as already used).
    case defaultQuality
    /// Nearest-neighbor (pixelated upscale).
    case nearest
    /// Lanczos high-quality filter.
    case lanczos
}

/// Select resample quality from scale direction and the two user options.
/// - Parameter scale: target/source size ratio; `> 1` = upsampling, `< 1` = downsampling, `== 1` = 1:1.
/// - Parameter useNearestWhenUpsampling: when true and scale > 1, use nearest.
/// - Parameter useLanczosWhenDownsampling: when true and scale < 1, use Lanczos.
/// - Returns: filter kind for the resize call site.
func selectResampleFilter(
    scale: CGFloat,
    useNearestWhenUpsampling: Bool,
    useLanczosWhenDownsampling: Bool
) -> ResampleFilterKind {
    if scale > 1.0 && useNearestWhenUpsampling {
        return .nearest
    }
    if scale < 1.0 && useLanczosWhenDownsampling {
        return .lanczos
    }
    return .defaultQuality
}

/// Map selection to Core Graphics interpolation quality.
func cgInterpolationQuality(for kind: ResampleFilterKind) -> CGInterpolationQuality {
    switch kind {
    case .nearest:
        return .none
    case .lanczos:
        // CG has no Lanczos; callers should prefer the CI path for true Lanczos.
        // When staying on CG, use highest available quality.
        return .high
    case .defaultQuality:
        return .high
    }
}

/// Whether the CI resize path should use `CILanczosScaleTransform` (true) or a plain affine scale (false).
func shouldUseCILanczos(for kind: ResampleFilterKind) -> Bool {
    switch kind {
    case .nearest:
        return false
    case .lanczos:
        return true
    case .defaultQuality:
        // Prior CI behavior always used Lanczos.
        return true
    }
}
