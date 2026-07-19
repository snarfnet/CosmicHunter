import SwiftUI

struct RecordsView: View {
    @ObservedObject var store: HitStore
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            ZStack {
                Retro.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        rankCard
                        if store.records.isEmpty {
                            emptyState
                        } else {
                            ForEach(store.records) { rec in
                                recordRow(rec)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(L("記録", "Records"))
            .toolbar {
                if !store.records.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) { confirmClear = true } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .confirmationDialog(L("記録を消去しますか？", "Clear all records?"),
                                isPresented: $confirmClear, titleVisibility: .visible) {
                Button(L("消去", "Clear"), role: .destructive) { store.clearAll() }
                Button(L("キャンセル", "Cancel"), role: .cancel) {}
            }
        }
    }

    private var rankCard: some View {
        VStack(spacing: 12) {
            Text(store.currentRank.symbol)
                .font(.system(size: 40))
                .foregroundStyle(Retro.star)
            Text(store.currentRank.title)
                .font(.title3.bold())
                .foregroundStyle(Retro.dial)
            Text(L("累計ヒット \(store.lifetimeHits)", "Lifetime hits \(store.lifetimeHits)"))
                .font(.callout)
                .foregroundStyle(Retro.lcd)

            if let next = store.nextRank {
                ProgressView(value: store.progress)
                    .tint(Retro.needle)
                Text(L("次の階級「\(next.title)」まで \(next.minHits - store.lifetimeHits)",
                       "\(next.minHits - store.lifetimeHits) to \(next.title)"))
                    .font(.caption)
                    .foregroundStyle(Retro.lcdDim)
            } else {
                Text(L("最高階級に到達！", "Maximum rank reached!"))
                    .font(.caption)
                    .foregroundStyle(Retro.amber)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Retro.panel)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func recordRow(_ rec: HitRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(rec.date, style: .date).foregroundStyle(Retro.dial)
                Text(rec.date, style: .time).foregroundStyle(Retro.lcdDim)
                Spacer()
                Text("\(rec.totalHits) hits").bold().foregroundStyle(Retro.lcd)
            }
            HStack(spacing: 16) {
                stat(L("時間", "Time"), "\(rec.durationSeconds)s")
                stat(L("平均", "Avg"), String(format: "%.1f", rec.avgHitsPerMin))
                stat(L("最大", "Peak"), String(format: "%.0f", rec.peakHitsPerMin))
                if let alt = rec.altitude {
                    stat(L("標高", "Alt"), String(format: "%.0fm", alt))
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Retro.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).foregroundStyle(Retro.lcdDim)
            Text(value).foregroundStyle(Retro.dial)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "star.slash")
                .font(.system(size: 40))
                .foregroundStyle(Retro.lcdDim)
            Text(L("まだ記録がありません", "No records yet"))
                .foregroundStyle(Retro.lcdDim)
            Text(L("観測を開始して宇宙線を集めましょう", "Start observing to collect cosmic rays"))
                .font(.caption)
                .foregroundStyle(Retro.lcdDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
