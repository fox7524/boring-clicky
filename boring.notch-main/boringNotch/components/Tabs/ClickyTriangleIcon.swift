import SwiftUI

/// Clicky’s triangle cursor icon (equilateral triangle rotated ~35°).
/// We keep it "templateable" by inheriting the foreground color.
struct ClickyTriangleIcon: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let height = size * sqrt(3.0) / 2.0
            let cx = geo.size.width * 0.5
            let cy = geo.size.height * 0.5

            Path { path in
                let top = CGPoint(x: cx, y: cy - height / 1.5)
                let bottomLeft = CGPoint(x: cx - size / 2, y: cy + height / 3)
                let bottomRight = CGPoint(x: cx + size / 2, y: cy + height / 3)
                path.move(to: top)
                path.addLine(to: bottomLeft)
                path.addLine(to: bottomRight)
                path.closeSubpath()
            }
            .rotation(Angle(degrees: 35), anchor: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

