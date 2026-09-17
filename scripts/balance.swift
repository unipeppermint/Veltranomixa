import Foundation
struct Seeded: RandomSource {
    var seed: UInt64 = 42
    mutating func nextIndex() -> Int { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return Int((seed >> 32) % 8) }
}
@main struct Balance {
    static func main() throws {
        var random = Seeded()
        print("level,name,wins,runs,winRate,averageSpins")
        for level in Content.levels {
            var won = 0, spins = 0
            for _ in 0..<1000 {
                var s = SaveEnvelope(); s.completed = Set(0..<level.id); try GameEngine.start(level.id, in: &s)
                for _ in 0..<300 {
                    guard let r = s.run else { break }
                    if r.phase == .won || r.phase == .lost { break }
                    if let pending = r.pending { try GameEngine.acknowledge(&s,id:pending.id); continue }
                    if r.phase == .upgrade {
                        let choice: Upgrade
                        if r.remaining <= 3 { choice = .reserve }
                        else if r.wood < level.wood { choice = .tools }
                        else { choice = r.offers.first(where: { [.purse,.shellwork,.savings,.beach,.tide].contains($0) }) ?? .reserve }
                        try GameEngine.choose(choice,in:&s)
                    } else {
                        if r.coins >= level.coins + 4 && r.wood < level.wood && r.boost < 3 { try GameEngine.craft(&s) }
                        try GameEngine.spin(&s,random:&random)
                    }
                }
                if s.run!.phase == .won { won += 1 }; spins += s.run!.spins
            }
            print("\(level.id+1),\(level.name),\(won),1000,\(Double(won)/10)%,\(Double(spins)/1000)")
        }
    }
}
