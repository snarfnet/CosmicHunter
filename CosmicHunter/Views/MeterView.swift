import SwiftUI

/// Analog needle gauge for the current hit rate.
struct MeterView: View {
    var value: Double
    var maxValue: Double

    private let startAngle = -120.0
    private let endAngle = 120.0

    private var fraction: Double { min(1, max(0, value / maxValue)) }
    private var needleAngle: Double { startAngle + (endAngle - startAngle) * fraction }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Retro.panel, Retro.bg],
                                         center: .center, startRadius: 0, endRadius: size / 2))
                    .overlay(Circle().stroke(Retro.bezel, lineWidth: size * 0.03))

                colorArc(size: size)
                ticks(size: size)
                needle(size: size)

                Circle()
                    .fill(Retro.bezel)
                    .frame(width: size * 0.10, height: size * 0.10)
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func colorArc(size: CGFloat) -> some View {
        let r = size * 0.40
        return ZStack {
            arc(from: startAngle, to: -40, color: Retro.lcd, r: r, size: size)
            arc(from: -40, to: 40, color: Retro.amber, r: r, size: size)
            arc(from: 40, to: endAngle, color: Color(red: 1, green: 0.45, blue: 0.4), r: r, size: size)
        }
    }

    private func arc(from: Double, to: Double, color: Color, r: CGFloat, size: CGFloat) -> some View {
        Path { p in
            p.addArc(center: CGPoint(x: size / 2, y: size / 2), radius: r,
                     startAngle: .degrees(from - 90), endAngle: .degrees(to - 90), clockwise: false)
        }
        .stroke(color.opacity(0.65), style: StrokeStyle(lineWidth: size * 0.03, lineCap: .round))
    }

    private func ticks(size: CGFloat) -> some View {
        ForEach(0..<11) { i in
            let frac = Double(i) / 10.0
            let ang = startAngle + (endAngle - startAngle) * frac
            Rectangle()
                .fill(Retro.dial.opacity(0.7))
                .frame(width: size * 0.008, height: i % 5 == 0 ? size * 0.06 : size * 0.035)
                .offset(y: -size * 0.34)
                .rotationEffect(.degrees(ang))
        }
    }

    private func needle(size: CGFloat) -> some View {
        Rectangle()
            .fill(Retro.needle)
            .frame(width: size * 0.012, height: size * 0.38)
            .offset(y: -size * 0.15)
            .rotationEffect(.degrees(needleAngle))
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: needleAngle)
            .shadow(color: Retro.needle.opacity(0.6), radius: 4)
    }
}
