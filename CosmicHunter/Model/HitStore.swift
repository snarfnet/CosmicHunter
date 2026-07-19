import Foundation

struct HitRecord: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let durationSeconds: Int
    let totalHits: Int
    let avgHitsPerMin: Double
    let peakHitsPerMin: Double
    let altitude: Double?
}

struct Rank {
    let title: String
    let minHits: Int
    let symbol: String
}

/// Cumulative lifetime hits drive a simple rank ladder for a bit of gamification.
final class HitStore: ObservableObject {
    @Published private(set) var records: [HitRecord] = []
    @Published private(set) var lifetimeHits: Int = 0

    private let recordsKey = "cosmichunter.records"
    private let lifetimeKey = "cosmichunter.lifetime"

    static let ranks: [Rank] = [
        Rank(title: "見習い観測者",  minHits: 0,     symbol: "✦"),
        Rank(title: "星屑ハンター",  minHits: 100,   symbol: "✦✦"),
        Rank(title: "ミューオン追跡者", minHits: 1000, symbol: "✦✦✦"),
        Rank(title: "宇宙線マスター", minHits: 5000,  symbol: "★"),
        Rank(title: "銀河の番人",    minHits: 20000, symbol: "★★"),
        Rank(title: "コスミック・レジェンド", minHits: 100000, symbol: "★★★"),
    ]

    static let ranksEn: [Rank] = [
        Rank(title: "Apprentice Observer", minHits: 0,     symbol: "✦"),
        Rank(title: "Stardust Hunter",     minHits: 100,   symbol: "✦✦"),
        Rank(title: "Muon Tracker",        minHits: 1000,  symbol: "✦✦✦"),
        Rank(title: "Cosmic Ray Master",   minHits: 5000,  symbol: "★"),
        Rank(title: "Galactic Warden",     minHits: 20000, symbol: "★★"),
        Rank(title: "Cosmic Legend",       minHits: 100000, symbol: "★★★"),
    ]

    private var ladder: [Rank] { isJa ? Self.ranks : Self.ranksEn }

    var currentRank: Rank {
        ladder.last { lifetimeHits >= $0.minHits } ?? ladder[0]
    }

    var nextRank: Rank? {
        ladder.first { lifetimeHits < $0.minHits }
    }

    /// Progress 0..1 toward the next rank.
    var progress: Double {
        guard let next = nextRank else { return 1 }
        let cur = currentRank.minHits
        let span = next.minHits - cur
        guard span > 0 else { return 1 }
        return min(1, max(0, Double(lifetimeHits - cur) / Double(span)))
    }

    init() { load() }

    func add(_ record: HitRecord) {
        records.insert(record, at: 0)
        lifetimeHits += record.totalHits
        save()
    }

    func clearAll() {
        records = []
        save()
    }

    private func load() {
        let d = UserDefaults.standard
        if let data = d.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([HitRecord].self, from: data) {
            records = decoded
        }
        lifetimeHits = d.integer(forKey: lifetimeKey)
    }

    private func save() {
        let d = UserDefaults.standard
        if let data = try? JSONEncoder().encode(records) {
            d.set(data, forKey: recordsKey)
        }
        d.set(lifetimeHits, forKey: lifetimeKey)
    }

    func loadDemoState() {
        lifetimeHits = 1240
        records = [
            HitRecord(date: Date().addingTimeInterval(-3600), durationSeconds: 300,
                      totalHits: 34, avgHitsPerMin: 6.8, peakHitsPerMin: 14, altitude: 634),
            HitRecord(date: Date().addingTimeInterval(-90000), durationSeconds: 600,
                      totalHits: 71, avgHitsPerMin: 7.1, peakHitsPerMin: 19, altitude: 21),
        ]
    }
}
