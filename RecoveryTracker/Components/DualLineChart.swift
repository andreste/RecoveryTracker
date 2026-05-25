import SwiftUI

struct DualLineChart: View {
    let hrv: [Double]    // HRV values in ms (~45–80 range)
    let load: [Double]   // Training load in au (~100–480 range)
    var chartHeight: CGFloat = 140

    var body: some View {
        GeometryReader { geo in
            ChartCanvas(
                hrv: hrv, load: load,
                width: geo.size.width,
                height: chartHeight
            )
        }
        .frame(height: chartHeight)
    }
}

private struct ChartCanvas: View {
    let hrv: [Double]
    let load: [Double]
    let width: CGFloat
    let height: CGFloat

    private let padH: CGFloat = 4
    private let padV: CGFloat = 10
    private let hMin: Double = 45, hMax: Double = 80
    private let lMin: Double = 100, lMax: Double = 480

    private var n: Int { hrv.count }
    private var iw: CGFloat { width - padH * 2 }
    private var ih: CGFloat { height - padV * 2 }
    private var stepX: CGFloat { n > 1 ? iw / CGFloat(n - 1) : iw }

    private func hrvPoint(at i: Int) -> CGPoint {
        CGPoint(
            x: padH + CGFloat(i) * stepX,
            y: padV + ih - CGFloat((hrv[i] - hMin) / (hMax - hMin)) * ih
        )
    }

    private func loadPoint(at i: Int) -> CGPoint {
        CGPoint(
            x: padH + CGFloat(i) * stepX,
            y: padV + ih - CGFloat((load[i] - lMin) / (lMax - lMin)) * ih
        )
    }

    private func linePath(_ points: [CGPoint]) -> Path {
        Path { p in
            guard let first = points.first else { return }
            p.move(to: first)
            for pt in points.dropFirst() { p.addLine(to: pt) }
        }
    }

    var body: some View {
        let hrvPts  = (0..<n).map { hrvPoint(at: $0) }
        let loadPts = (0..<n).map { loadPoint(at: $0) }

        ZStack(alignment: .topLeading) {
            // Horizontal dashed grid lines
            ForEach(0..<4, id: \.self) { i in
                let y = padV + (ih / 3) * CGFloat(i)
                Path { p in
                    p.move(to: CGPoint(x: padH, y: y))
                    p.addLine(to: CGPoint(x: width - padH, y: y))
                }
                .stroke(Color.rtSeparator, style: StrokeStyle(lineWidth: 0.8, dash: [2, 3]))
            }

            // HRV area fill
            Path { p in
                guard let first = hrvPts.first, let last = hrvPts.last else { return }
                p.move(to: CGPoint(x: first.x, y: padV + ih))
                for pt in hrvPts { p.addLine(to: pt) }
                p.addLine(to: CGPoint(x: last.x, y: padV + ih))
                p.closeSubpath()
            }
            .fill(LinearGradient(
                gradient: Gradient(colors: [Color.rtTeal.opacity(0.25), Color.rtTeal.opacity(0)]),
                startPoint: .top, endPoint: .bottom
            ))

            // Training load line (amber)
            linePath(loadPts)
                .stroke(Color.rtAmber, style: StrokeStyle(lineWidth: 1.5))
                .opacity(0.85)

            // HRV line (teal)
            linePath(hrvPts)
                .stroke(Color.rtTeal, style: StrokeStyle(lineWidth: 2.2))

            // Today dot
            if let last = hrvPts.last {
                Circle()
                    .fill(Color.rtTeal)
                    .frame(width: 7, height: 7)
                    .overlay(Circle().stroke(Color.rtCard, lineWidth: 1.5))
                    .position(last)
            }
        }
    }
}

#Preview {
    Card {
        DualLineChart(
            hrv:  [62,58,60,64,66,63,59,55,52,58,62,64,68,70,67,63,66,70,72,69,65,60,63,68,71,74,70,72],
            load: [240,260,310,180,200,420,380,340,200,150,260,310,290,260,200,420,440,360,260,200,300,460,420,360,260,180,260,310]
        )
    }
    .padding()
    .background(Color.rtBackground)
}
