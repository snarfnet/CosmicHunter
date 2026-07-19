import SwiftUI

struct GuideView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Retro.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        section(L("使い方", "How to use")) {
                            step("1", L("背面カメラのレンズを指やテープでしっかり覆い、真っ暗にします。",
                                        "Cover the rear camera lens tightly with a finger or tape so it goes fully dark."))
                            step("2", L("「観測開始」をタップ。自動で較正し、センサーのノイズを記録します。",
                                        "Tap Start. It auto-calibrates and records the sensor noise floor."))
                            step("3", L("宇宙線がセンサーに当たると点として検出され、カウントされます。",
                                        "When a cosmic ray strikes the sensor it registers as a point and gets counted."))
                            step("4", L("観測をやめると記録が保存され、累計ヒットで階級が上がります。",
                                        "Stop to save the session — lifetime hits raise your rank."))
                        }
                        section(L("原理", "How it works")) {
                            para(L("宇宙から降り注ぐ高エネルギー粒子（主にミューオン）や自然放射線がカメラのCMOSセンサーを通ると、その画素に電荷を残します。暗くしたフレームでは、この電荷が周囲より明るい点として現れます。アプリはこの点を数えています。",
                                   "High-energy particles from space (mostly muons) and natural radiation deposit charge in the camera's CMOS pixels. In a dark frame that charge shows up as a bright point above the surrounding noise. The app counts those points."))
                        }
                        section(L("標高とヒット数", "Altitude and hits")) {
                            para(L("宇宙線は標高が高いほど強くなります。目安として1500m上がるごとに約2倍。飛行機の中や山の上では、ヒット数が増えるのを観察できます。",
                                   "Cosmic rays get stronger with altitude — roughly double every 1500 m. On a plane or a mountain you can watch the hit count climb."))
                        }
                        disclaimer
                    }
                    .padding()
                }
            }
            .navigationTitle(L("使い方", "Guide"))
        }
    }

    private func section(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3.bold()).foregroundStyle(Retro.lcd)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Retro.panel)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func step(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num)
                .font(.headline)
                .foregroundStyle(Retro.bg)
                .frame(width: 28, height: 28)
                .background(Retro.lcd)
                .clipShape(Circle())
            Text(text).foregroundStyle(Retro.dial)
        }
    }

    private func para(_ text: String) -> some View {
        Text(text).foregroundStyle(Retro.dial).fixedSize(horizontal: false, vertical: true)
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(L("これは科学の入り口として楽しむアプリです。正確な放射線量計や検出器の代わりにはなりません。ヒット数はセンサーやノイズの状態でも変わります。",
                   "This is an app to enjoy as a gateway to science. It is not a substitute for a calibrated radiation meter or detector. Hit counts also vary with sensor and noise conditions."))
                .font(.callout)
        }
        .foregroundStyle(Retro.amber)
        .padding()
        .background(Retro.amber.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
