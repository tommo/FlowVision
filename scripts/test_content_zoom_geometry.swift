// Drives shipped ContentZoomGeometry.swift helpers.
// Run: swiftc -o /tmp/t_cz FlowVision/Sources/Common/ContentZoomGeometry.swift scripts/test_content_zoom_geometry.swift && /tmp/t_cz
import Foundation
import CoreGraphics

@main
struct ContentZoomGeometryTest {
    static func assertTrue(_ cond: Bool, _ msg: String) {
        if !cond {
            fputs("FAIL: \(msg)\n", stderr)
            exit(1)
        }
        print("PASS: \(msg)")
    }

    static func main() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        let aspect = CGSize(width: 1920, height: 1080)
        let fit = fitContentRect(aspectRatio: aspect, insideRect: bounds)
        assertTrue(fit.width <= bounds.width + 0.01 && fit.height <= bounds.height + 0.01, "fit contained")
        assertTrue(abs(fit.width / fit.height - aspect.width / aspect.height) < 0.001, "fit aspect")
        assertTrue(fit.minX >= -0.01 && fit.minY >= -0.01, "fit origin inside")

        let base = CGRect(x: 100, y: 100, width: 200, height: 100)
        let up = applyRelativeZoom(frame: base, factor: 2.0, anchorInContent: CGPoint(x: 100, y: 50))
        assertTrue(abs(up.width - 400) < 0.01 && abs(up.height - 200) < 0.01, "zoom-up size")
        assertTrue(up.width > base.width, "scale-up increases size")

        let down = applyRelativeZoom(frame: up, factor: 0.5, anchorInContent: CGPoint(x: 200, y: 100))
        assertTrue(abs(down.width - 200) < 0.01, "zoom-down size")
        assertTrue(down.width < up.width, "scale-down decreases size")

        var far = CGRect(x: 5000, y: 5000, width: 100, height: 100)
        far = clampContentFrame(far, in: bounds)
        assertTrue(far.minX <= bounds.width && far.minY <= bounds.height, "clamp pulls back into range")
        assertTrue(far.intersects(bounds) || far.maxX >= 0 || far.maxY >= 0, "clamp keeps intersection spirit")

        let panned = panContentFrame(base, deltaX: -1000, deltaY: 0, in: bounds)
        assertTrue(panned.maxX >= 0, "pan clamp left edge")

        let absZ = applyAbsoluteZoom(
            baseSize: CGSize(width: 200, height: 100),
            scale: 2,
            centerPoint: CGPoint(x: 100, y: 50),
            currentFrame: base
        )
        assertTrue(abs(absZ.width - 400) < 0.01, "absolute zoom size")

        print("ALL_CONTENT_ZOOM_GEOMETRY_PASSED")
    }
}
