import SwiftUI

struct ObserveScreen: View {
    @ObservedObject var detector: CosmicDetector
    @ObservedObject var store: HitStore
    @ObservedObject var altitude: AltitudeService

    private let click = ClickPlayer()
    @State private var soundOn = true
    @State private var startedAt: Date?
    @State private var peakRate: Double = 0

    var body: some View {
        ZStack {
            Retro.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    header
                    meterPanel
                    lcdPanel
                    altitudePanel
                    warningBar
                    controls
                }
                .padding()
            }
        }
        .onAppear {
            detector.onHit = { _ in if soundOn { click.click() } }
            altitude.request()
        }
        .onChange(of: detector.hitsPerMin) { _, v in
            if v > peakRate { peakRate = v }
        }
    }

    private var header: some View {
        HStack {
            Text(L("宇宙線ハンター", "Cosmic Ray Hunter"))
                .font(.title2.bold())
                .foregroundStyle(Retro.dial)
            Spacer()
            Circle()
                .fill(detector.isRunning ? Retro.lcd : Retro.lcdDim)
                .frame(width: 12, height: 12)
                .shadow(color: detector.isRunning ? Retro.lcd : .clear, radius: 6)
        }
    }

    private var meterPanel: some View {
        VStack(spacing: 6) {
            MeterView(value: detector.hitsPerMin, maxValue: 50)
                .frame(height: 220)
            Text(L("ヒット / 分", "hits / min"))
                .font(.caption)
                .foregroundStyle(Retro.lcdDim)
        }
        .padding()
        .background(Retro.panel)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var lcdPanel: some View {
        HStack(spacing: 12) {
            lcdBox(L("レート", "RATE"), String(format: "%.0f", detector.hitsPerMin),
                   Retro.rateColor(detector.hitsPerMin))
            lcdBox(L("累計", "COUNT"), "\(detector.totalHits)", Retro.lcd)
        }
    }

    private func lcdBox(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(Retro.lcdDim)
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.5), radius: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Retro.bg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var altitudePanel: some View {
        if let alt = altitude.altitude {
            HStack {
                Image(systemName: "mountain.2.fill").foregroundStyle(Retro.star)
                Text(L("標高", "Altitude"))
                    .foregroundStyle(Retro.lcdDim)
                Spacer()
                Text(String(format: "%.0f m", alt)).foregroundStyle(Retro.dial).bold()
                if let flux = altitude.relativeFlux {
                    Text(String(format: "×%.1f", flux))
                        .font(.caption)
                        .foregroundStyle(Retro.amber)
                }
            }
            .padding()
            .background(Retro.panel)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private var warningBar: some View {
        if detector.permissionDenied {
            warn(L("カメラを許可してください", "Please allow camera access"))
        } else if detector.isCalibrating {
            warn(L("較正中… センサーを暗くしてお待ちください", "Calibrating… keep the sensor dark"))
        } else if detector.isRunning && detector.frameBrightness > 20 {
            warn(L("明るすぎます。レンズを指で覆ってください", "Too bright — cover the lens with a finger"))
        }
    }

    private func warn(_ text: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text).font(.callout)
        }
        .foregroundStyle(Retro.amber)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Retro.amber.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                if detector.isRunning { stopSession() } else { startSession() }
            } label: {
                Text(detector.isRunning ? L("観測停止", "Stop") : L("観測開始", "Start"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(detector.isRunning ? Color(red: 0.6, green: 0.2, blue: 0.2) : Retro.needle)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            HStack(spacing: 12) {
                Button {
                    detector.calibrate()
                } label: {
                    Label(L("較正", "Calibrate"), systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Retro.panel)
                        .foregroundStyle(Retro.dial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!detector.isRunning)

                Toggle(isOn: $soundOn) {
                    Label(L("音", "Sound"), systemImage: soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
                .toggleStyle(.button)
                .tint(Retro.lcd)
                .padding()
                .background(Retro.panel)
                .foregroundStyle(Retro.dial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .onChange(of: soundOn) { _, v in click.setEnabled(v) }
            }
        }
    }

    private func startSession() {
        peakRate = 0
        startedAt = Date()
        detector.start()
    }

    private func stopSession() {
        detector.stop()
        guard let s = startedAt else { return }
        let dur = Int(Date().timeIntervalSince(s))
        if detector.totalHits > 0 && dur > 3 {
            let avg = Double(detector.totalHits) / max(1, Double(dur) / 60.0)
            store.add(HitRecord(date: Date(), durationSeconds: dur,
                                totalHits: detector.totalHits, avgHitsPerMin: avg,
                                peakHitsPerMin: peakRate, altitude: altitude.altitude))
        }
        startedAt = nil
    }
}
