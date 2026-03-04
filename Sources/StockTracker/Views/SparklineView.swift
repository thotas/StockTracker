import SwiftUI

struct SparklineView: View {
    let data: [Double]
    let isPositive: Bool
    var lineWidth: CGFloat = 1.5

    private var lineColor: Color {
        isPositive
            ? Color(red: 0.18, green: 0.80, blue: 0.44)
            : Color(red: 0.95, green: 0.27, blue: 0.27)
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard data.count > 1 else { return [] }
        let minV = data.min()!
        let maxV = data.max()!
        let range = maxV == minV ? 1.0 : (maxV - minV)
        let step = size.width / CGFloat(data.count - 1)
        return data.enumerated().map { i, v in
            let x = CGFloat(i) * step
            let norm = CGFloat((v - minV) / range)
            let y = size.height - norm * size.height * 0.85 - size.height * 0.075
            return CGPoint(x: x, y: y)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let pts = points(in: geo.size)
            let w = geo.size.width
            let h = geo.size.height

            if pts.count > 1 {
                ZStack {
                    // Gradient fill under line
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h))
                        p.addLine(to: pts[0])
                        for pt in pts.dropFirst() { p.addLine(to: pt) }
                        p.addLine(to: CGPoint(x: w, y: h))
                        p.closeSubpath()
                    }
                    .fill(LinearGradient(
                        colors: [lineColor.opacity(0.35), lineColor.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    ))

                    // Line
                    Path { p in
                        p.move(to: pts[0])
                        for pt in pts.dropFirst() { p.addLine(to: pt) }
                    }
                    .stroke(lineColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
}
