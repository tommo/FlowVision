// Run: swiftc -o /tmp/t_iz FlowVision/Sources/Common/InitialZoom.swift scripts/test_initial_zoom.swift && /tmp/t_iz
import Foundation
import CoreGraphics

@main
struct InitialZoomLogicTest {
    static func main() {
        let bounds = CGSize(width: 800, height: 600)
        let small = CGSize(width: 200, height: 100)
        let large = CGSize(width: 4000, height: 3000)
        let scale: CGFloat = 2

        let actS = computeInitialLargeImageSize(originalSize: small, maxBounds: bounds, backingScale: scale, mode: .actual)
        precondition(abs(actS.width - 100) < 0.5 && abs(actS.height - 50) < 0.5)

        let actL = computeInitialLargeImageSize(originalSize: large, maxBounds: bounds, backingScale: scale, mode: .actual)
        let fitL = computeInitialLargeImageSize(originalSize: large, maxBounds: bounds, backingScale: scale, mode: .fit)
        precondition(abs(actL.width - fitL.width) < 0.5)

        let fill = computeInitialLargeImageSize(originalSize: large, maxBounds: bounds, backingScale: scale, mode: .fill)
        precondition(fill.width >= bounds.width - 0.5 || fill.height >= bounds.height - 0.5)

        print("ALL_INITIAL_ZOOM_PASSED")
    }
}
