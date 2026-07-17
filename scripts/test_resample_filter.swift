//
//  test_resample_filter.swift
//  Drives the shipped selectResampleFilter helpers (ResampleFilter.swift).
//
//  Run from repo root:
//    swiftc -o /tmp/test_resample \
//      FlowVision/Sources/Common/ResampleFilter.swift \
//      scripts/test_resample_filter.swift \
//    && /tmp/test_resample
//

import Foundation
import CoreGraphics

@main
struct ResampleFilterLogicTest {
    static func assertEq<T: Equatable>(_ a: T, _ b: T, _ label: String) {
        if a != b {
            fputs("FAIL: \(label): got \(a), expected \(b)\n", stderr)
            exit(1)
        }
        print("PASS: \(label)")
    }

    static func main() {
        // Enabled nearest chosen for scale > 1
        assertEq(
            selectResampleFilter(scale: 2.0, useNearestWhenUpsampling: true, useLanczosWhenDownsampling: false),
            .nearest,
            "upsample+nearest-on => nearest"
        )
        // Disabled nearest falls back to prior/default for upscale
        assertEq(
            selectResampleFilter(scale: 2.0, useNearestWhenUpsampling: false, useLanczosWhenDownsampling: true),
            .defaultQuality,
            "upsample+nearest-off => default"
        )
        // Enabled Lanczos chosen for scale < 1
        assertEq(
            selectResampleFilter(scale: 0.5, useNearestWhenUpsampling: false, useLanczosWhenDownsampling: true),
            .lanczos,
            "downsample+lanczos-on => lanczos"
        )
        // Disabled Lanczos falls back to prior/default for downscale
        assertEq(
            selectResampleFilter(scale: 0.5, useNearestWhenUpsampling: true, useLanczosWhenDownsampling: false),
            .defaultQuality,
            "downsample+lanczos-off => default"
        )
        // 1:1 keeps default regardless of options
        assertEq(
            selectResampleFilter(scale: 1.0, useNearestWhenUpsampling: true, useLanczosWhenDownsampling: true),
            .defaultQuality,
            "scale==1 => default"
        )
        assertEq(
            cgInterpolationQuality(for: .nearest).rawValue,
            CGInterpolationQuality.none.rawValue,
            "nearest => CG none"
        )
        assertEq(
            cgInterpolationQuality(for: .defaultQuality).rawValue,
            CGInterpolationQuality.high.rawValue,
            "default => CG high"
        )
        assertEq(shouldUseCILanczos(for: .nearest), false, "nearest => no CI Lanczos")
        assertEq(shouldUseCILanczos(for: .lanczos), true, "lanczos => CI Lanczos")
        assertEq(shouldUseCILanczos(for: .defaultQuality), true, "default CI => Lanczos (prior)")

        print("ALL_RESAMPLE_LOGIC_PASSED")
    }
}
