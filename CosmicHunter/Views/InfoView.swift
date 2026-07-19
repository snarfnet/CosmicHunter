import SwiftUI

struct InfoView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Retro.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        card(L("このアプリについて", "About")) {
                            infoRow(L("宇宙線ハンターは、スマホのカメラセンサーで宇宙から届く粒子をとらえる観測ツールです。暗くしたセンサーに当たる高エネルギー粒子を数え、ヒット数で階級が上がります。",
                                      "Cosmic Ray Hunter turns your phone's camera sensor into a particle observatory. It counts high-energy particles striking the darkened sensor, and your rank rises with the hit count."))
                        }
                        card(L("プライバシー", "Privacy")) {
                            infoRow(L("写真や記録は端末内にだけ保存され、どこにも送りません。位置情報は標高の表示だけに使い、任意です。ことわっても観測はできます。",
                                      "Photos and records stay only on your device and are never uploaded. Location is used solely to show altitude and is optional — you can observe without it."))
                        }
                        card(L("免責", "Disclaimer")) {
                            infoRow(L("本物の放射線検出器ではありません。教育・エンターテインメント目的のアプリです。",
                                      "This is not a real radiation detector. It is for education and entertainment."))
                        }
                        card(L("サポート", "Support")) {
                            Link(L("サポートページ", "Support page"),
                                 destination: URL(string: "https://snarfnet.github.io/")!)
                                .foregroundStyle(Retro.lcd)
                        }
                        Text("© 2026 tokyonasu")
                            .font(.caption)
                            .foregroundStyle(Retro.lcdDim)
                    }
                    .padding()
                }
            }
            .navigationTitle(L("情報", "Info"))
        }
    }

    private func card(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(Retro.lcd)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Retro.panel)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func infoRow(_ text: String) -> some View {
        Text(text).foregroundStyle(Retro.dial).fixedSize(horizontal: false, vertical: true)
    }
}
