import Foundation

enum Tile: String, Codable, CaseIterable {
    case wood, coin, chest, wind, shell, supply
    var title: String { ["wood":"Wood", "coin":"Coins", "chest":"Chest", "wind":"Breeze", "shell":"Shells", "supply":"Supply"][rawValue]! }
    var symbol: String { ["wood":"leaf.fill", "coin":"dollarsign.circle.fill", "chest":"shippingbox.fill", "wind":"wind", "shell":"fan.fill", "supply":"ticket.fill"][rawValue]! }
}
struct Segment: Codable, Equatable { var kind: Tile; var value: Int }
enum IslandRule: String {
    case calm, grove, tide, market
    var title: String {
        switch self { case .calm: return "Free workshop"; case .grove: return "Grove neighbors"; case .tide: return "Tidal rhythm"; case .market: return "Island market" }
    }
    var detail: String {
        switch self {
        case .calm: return "Your first tile swap is free. Each extra tile of a resource raises its chance by 12.5 percentage points."
        case .grove: return "Wood gains +1 for each neighboring Wood tile, before Breeze. The first and last tiles are neighbors."
        case .tide: return "High tide every third spin: Shells +3. On other spins, Wood +1, before Breeze."
        case .market: return "Odd spins: Wood +2. Even spins: Coins +2. Breeze applies afterward. Plan for both resources."
        }
    }
}
struct Level {
    let id: Int
    let name: String
    let story: String
    let wood: Int
    let coins: Int
    let shells: Int
    let turns: Int
    var rule: IslandRule {
        switch id { case 3, 4, 6, 9: return .grove; case 5, 7, 10, 11, 13: return .tide; case 2, 8, 12, 14: return .market; default: return .calm }
    }
    var region: Int { id / 5 }
    var target: String { [(wood > 0 ? "Wood \(wood)" : nil), (coins > 0 ? "Coins \(coins)" : nil), (shells > 0 ? "Shells \(shells)" : nil)].compactMap { $0 }.joined(separator: " · ") }
    var reward: String { Content.buildings[min(id, 11)] }
    var wheel: [Segment] {
        var tiles: [Segment] = [.init(kind: .wood, value: 2), .init(kind: .coin, value: 2), .init(kind: .wood, value: 1), .init(kind: .wind, value: 0), .init(kind: .wood, value: 1), .init(kind: .coin, value: 1), .init(kind: .chest, value: 0), .init(kind: .coin, value: 3)]
        if id >= 5 { tiles[5] = .init(kind: .shell, value: 2) }
        if id >= 10 { tiles[7] = .init(kind: .supply, value: 1) }
        return tiles
    }
}
enum Content {
    static let regions = ["Breeze Harbor", "Blossom Hills", "Starlight Coast"]
    static let buildings = ["Coastal Lighthouse", "Seaside Cottage", "Fishing Hut", "Breeze Garden", "Wooden Bridge", "Sailboat", "Hilltop Windmill", "Wishing Fountain", "Orange Tree", "Glasshouse", "Stargazing Deck", "Festival Lights"]
    static let levels: [Level] = [
        .init(id: 0, name: "Light the Lighthouse", story: "Let the first light guide the boats home.", wood: 20, coins: 0, shells: 0, turns: 12),
        .init(id: 1, name: "A Seaside Home", story: "Gather Wood and save a few Coins for your new home.", wood: 16, coins: 5, shells: 0, turns: 14),
        .init(id: 2, name: "A Fisher's Morning", story: "Save Coins for fishing gear before spending them in the workshop.", wood: 0, coins: 18, shells: 0, turns: 13),
        .init(id: 3, name: "Harbor in Bloom", story: "Build a garden fence before your spins run out.", wood: 24, coins: 0, shells: 0, turns: 12),
        .init(id: 4, name: "Building Bridges", story: "Gather both resources to connect the harbor and hills.", wood: 22, coins: 8, shells: 0, turns: 16),
        .init(id: 5, name: "Letters from the Sea", story: "Shell tiles join your wheel. Collect gifts from the sea.", wood: 12, coins: 0, shells: 4, turns: 16),
        .init(id: 6, name: "Winds of Change", story: "Catch the breeze and make every piece of Wood count.", wood: 28, coins: 0, shells: 0, turns: 14),
        .init(id: 7, name: "A Fountain Wish", story: "Gather Coins and Shells for a sparkling fountain.", wood: 0, coins: 14, shells: 4, turns: 18),
        .init(id: 8, name: "Orange Season", story: "Plant a tree and let the sea breeze do the rest.", wood: 20, coins: 6, shells: 2, turns: 17),
        .init(id: 9, name: "Under Glass", story: "Balance workshop spending with three building resources.", wood: 24, coins: 8, shells: 4, turns: 20),
        .init(id: 10, name: "Look to the Stars", story: "Supply tiles return a spin and give you one Wood.", wood: 30, coins: 0, shells: 4, turns: 17),
        .init(id: 11, name: "Festival of Lights", story: "Decorate the coast with Shells and warm festival lights.", wood: 18, coins: 0, shells: 8, turns: 20),
        .init(id: 12, name: "Coral Sunset", story: "Complete the challenge to unlock the Coral wheel.", wood: 32, coins: 8, shells: 0, turns: 18),
        .init(id: 13, name: "Gifts of the Tide", story: "Gather ocean treasures to unlock the Starlight wheel.", wood: 0, coins: 12, shells: 10, turns: 22),
        .init(id: 14, name: "Island Festival", story: "The final stop across all three regions. Leave your mark on the island.", wood: 32, coins: 10, shells: 8, turns: 24)
    ]
}
enum Upgrade: String, Codable, CaseIterable {
    case tools, breeze, reserve, purse, shellwork, timber, savings, beach, exchange, workshop, sail, tide, bundle, compass, festival
    var title: String { ["Better Tools","Fair Breeze","Extra Chances","Coin Molds","Shell Craft","Driftwood","Savings Jar","Beach Walk","Timber Trade","Workshop Kit","Set Sail","Tidal Gifts","Full Cargo","Compass","Festival Gift"][Self.allCases.firstIndex(of: self)!] }
    var detail: String { ["All Wood tiles +1. Stacks.","Double the next Wood or Coins reward. Does not stack.","Gain 2 spins.","All Coins tiles +1.","All Shells tiles +1.","Gain 5 Wood now.","Gain 4 Coins now.","Gain 3 Shells now.","Spend 3 Coins to gain 8 Wood.","Wood tiles +1. Gain 1 Coin now.","Gain 1 spin and prepare Breeze.","Gain 2 Shells and 2 Coins.","Gain 3 Wood and 2 Coins.","Gain 1 spin and 2 Wood.","Gain 2 Wood, 2 Coins, and 1 Shell."][Self.allCases.firstIndex(of: self)!] }
}
enum Phase: String, Codable { case ready, upgrade, won, lost }
struct SpinRecord: Codable, Equatable {
    let id: UUID
    let index: Int
    let message: String
    // Legacy saves contain display text. Keep the transaction intact without showing old-language copy.
    var displayMessage: String {
        message.unicodeScalars.contains { (0x3400...0x9FFF).contains($0.value) }
            ? "Saved spin revealed. Your resources are up to date." : message
    }
}
struct RunState: Codable {
    var level: Int
    var wood = 0, coins = 0, shells = 0, spins = 0, boost = 0, coinBoost = 0, shellBoost = 0
    var remaining: Int
    var doubleNext = false
    var phase: Phase = .ready
    var pending: SpinRecord?
    var lastResult: SpinRecord?
    var wheel: [Segment]
    var offers: [Upgrade] = []
    var crafts = 0
    // Missing fields decode as nil in v1 saves: an existing run keeps its original rules.
    var mechanicsVersion: Int?
    var freeRefits: Int?
    var rule: IslandRule { mechanicsVersion == 1 ? Content.levels[level].rule : .calm }
    var replacementCost: Int { (freeRefits ?? 0) > 0 ? 0 : 6 }
    var canReplace: Bool { mechanicsVersion == 1 || level > 0 }
    var ruleStatus: String {
        guard mechanicsVersion == 1 else { return "Classic rules · Continue your original run" }
        switch rule {
        case .calm: return (freeRefits ?? 0) > 0 ? "Free workshop · First swap free" : "Free workshop · Swap for odds, boost for yield"
        case .grove: return "Grove · +1 per neighboring Wood tile"
        case .tide: return (spins + 1) % 3 == 0 ? "Next: high tide · Shells +3" : "Next: low tide · Wood +1 · High tide in \(3 - spins % 3) spins"
        case .market: return (spins + 1) % 2 == 1 ? "Next: timber market · Wood +2" : "Next: coin market · Coins +2"
        }
    }
    func probability(_ kind: Tile) -> Double { Double(wheel.filter { $0.kind == kind }.count) * 12.5 }
    func yield(at index: Int, spinNumber: Int) -> Int {
        let tile = wheel[index]
        var amount = tile.value + (tile.kind == .wood ? boost : (tile.kind == .coin ? coinBoost : (tile.kind == .shell ? shellBoost : 0)))
        if mechanicsVersion == 1 {
            switch rule {
            case .grove where tile.kind == .wood:
                amount += [wheel[(index + 7) % 8], wheel[(index + 1) % 8]].filter { $0.kind == .wood }.count
            case .tide:
                if spinNumber % 3 == 0 && tile.kind == .shell { amount += 3 }
                if spinNumber % 3 != 0 && tile.kind == .wood { amount += 1 }
            case .market:
                if (spinNumber % 2 == 1 && tile.kind == .wood) || (spinNumber % 2 == 0 && tile.kind == .coin) { amount += 2 }
            default: break
            }
        }
        return amount * (doubleNext && [.wood, .coin].contains(tile.kind) ? 2 : 1)
    }
    init(level: Level) {
        self.level = level.id; remaining = level.turns; wheel = level.wheel
        mechanicsVersion = 1; freeRefits = 1
    }
}
struct Preferences: Codable { var sound = true; var haptics = true; var fast = false; var skin = 0; var tutorialSeen = false }
struct SaveEnvelope: Codable {
    var version = 1
    var run: RunState?
    var completed: Set<Int> = []
    var medals: Set<Int> = []
    var totalSpins = 0, totalWood = 0, totalCrafts = 0, wins = 0
    var discovered: Set<Tile> = []
    var chosen: Set<Upgrade> = []
    var settings = Preferences()
    var achievements: [Bool] { [!completed.isEmpty, totalSpins >= 25, totalWood >= 100, totalCrafts >= 5, chosen.count >= 5, discovered.count == 6, completed.count >= 5, completed.count >= 10, medals.count >= 3, completed.count == 15] }
    static let achievementNames = ["First Light", "Spin Time", "Wood Collector", "Island Crafter", "Strategy Explorer", "Six Kinds of Luck", "Harbor Builder", "Hill Keeper", "Room to Spare", "Island Festival"]
    static let achievementDetails = ["Complete your first level.", "Spin 25 times in total.", "Collect 100 Wood in total.", "Make 5 workshop changes.", "Choose 5 different upgrades.", "Land on all 6 tile types.", "Complete 5 levels.", "Complete 10 levels.", "Finish the bonus challenge in 3 levels.", "Complete all 15 levels."]
}
protocol RandomSource { mutating func nextIndex() -> Int }
struct SystemRandomSource: RandomSource { mutating func nextIndex() -> Int { Int.random(in: 0..<8) } }
enum GameError: LocalizedError {
    case invalidAction, insufficientCoins, invalidSave
    var errorDescription: String? { switch self { case .invalidAction: return "Finish your current spin or upgrade first."; case .insufficientCoins: return "Not enough Coins. Gather a few more."; case .invalidSave: return "The save format or data is not compatible." } }
}
enum GameEngine {
    static func start(_ level: Int, in save: inout SaveEnvelope) throws {
        guard Content.levels.indices.contains(level), level == 0 || save.completed.contains(level - 1) else { throw GameError.invalidAction }
        save.run = RunState(level: Content.levels[level])
    }
    static func spin<R: RandomSource>(_ save: inout SaveEnvelope, random: inout R) throws {
        guard var r = save.run, r.phase == .ready, r.pending == nil, r.remaining > 0 else { throw GameError.invalidAction }
        let index = random.nextIndex()
        guard (0..<8).contains(index) else { throw GameError.invalidAction }
        let tile = r.wheel[index]
        r.remaining -= 1; r.spins += 1
        let oldWood = r.wood
        var message: String
        switch tile.kind {
        case .wood, .coin:
            let amount = r.yield(at: index, spinNumber: r.spins)
            if tile.kind == .wood { r.wood += amount } else { r.coins += amount }
            r.doubleNext = false; message = "\(tile.kind.title) +\(amount)"
        case .chest: message = "Chest found! Choose an upgrade."
        case .wind: r.doubleNext = true; message = "Breeze ready. Your next Wood or Coins reward is doubled."
        case .shell: let amount = r.yield(at: index, spinNumber: r.spins); r.shells += amount; message = "Shells +\(amount)"
        case .supply: r.remaining += 1; r.wood += 1; message = "Supply: +1 spin, +1 Wood"
        }
        save.totalSpins += 1; save.totalWood += r.wood - oldWood; save.discovered.insert(tile.kind)
        if meetsGoal(r) { win(&r, save: &save) }
        else if tile.kind == .chest || r.spins % 3 == 0 {
            r.phase = .upgrade
            if r.level == 0 { r.offers = [.tools, .breeze, .reserve] }
            else {
                let level = Content.levels[r.level]
                let growth: Upgrade = r.wood < level.wood ? .tools : (r.shells < level.shells ? .shellwork : .purse)
                let pool = Upgrade.allCases.filter {
                    $0 != growth && $0 != .reserve && (r.level >= 5 || ![.shellwork,.beach,.tide,.festival].contains($0)) && ($0 != .exchange || r.coins >= 3)
                }
                r.offers = [growth, .reserve, pool[(r.spins + r.level) % pool.count]]
            }
        } else if r.remaining == 0 { r.phase = .lost }
        r.pending = SpinRecord(id: UUID(), index: index, message: message)
        r.lastResult = r.pending
        save.run = r
    }
    static func acknowledge(_ save: inout SaveEnvelope, id: UUID) throws {
        guard save.run?.pending?.id == id else { throw GameError.invalidAction }; save.run?.pending = nil
    }
    static func choose(_ upgrade: Upgrade, in save: inout SaveEnvelope) throws {
        guard var r = save.run, r.phase == .upgrade, r.pending == nil, r.offers.contains(upgrade) else { throw GameError.invalidAction }
        let oldWood = r.wood
        switch upgrade {
        case .tools: r.boost += 1
        case .breeze: r.doubleNext = true
        case .reserve: r.remaining += 2
        case .purse: r.coinBoost += 1
        case .shellwork: r.shellBoost += 1
        case .timber: r.wood += 5
        case .savings: r.coins += 4
        case .beach: r.shells += 3
        case .exchange: guard r.coins >= 3 else { throw GameError.insufficientCoins }; r.coins -= 3; r.wood += 8
        case .workshop: r.boost += 1; r.coins += 1
        case .sail: r.remaining += 1; r.doubleNext = true
        case .tide: r.shells += 2; r.coins += 2
        case .bundle: r.wood += 3; r.coins += 2
        case .compass: r.remaining += 1; r.wood += 2
        case .festival: r.wood += 2; r.coins += 2; r.shells += 1
        }
        save.chosen.insert(upgrade); save.totalWood += r.wood - oldWood
        r.offers = []; r.phase = .ready
        if meetsGoal(r) { win(&r, save: &save) } else if r.remaining == 0 { r.phase = .lost }
        save.run = r
    }
    static func craft(_ save: inout SaveEnvelope, replacing: Int? = nil, with kind: Tile = .wood) throws {
        guard var r = save.run, r.phase == .ready, r.pending == nil else { throw GameError.invalidAction }
        let price = replacing == nil ? 4 : r.replacementCost
        guard r.coins >= price else { throw GameError.insufficientCoins }
        if let index = replacing {
            guard r.canReplace, r.wheel.indices.contains(index), [.wood,.coin,.shell].contains(kind), kind != .shell || r.level >= 5 else { throw GameError.invalidAction }
            guard r.wheel[index] != Segment(kind: kind, value: 2) else { throw GameError.invalidAction }
            r.wheel[index] = Segment(kind: kind, value: 2)
            if price == 0 { r.freeRefits = max(0, (r.freeRefits ?? 0) - 1) }
        } else { r.boost += 1 }
        r.coins -= price; r.crafts += 1; save.totalCrafts += 1; save.run = r
    }
    static func meetsGoal(_ r: RunState) -> Bool { let l = Content.levels[r.level]; return r.wood >= l.wood && r.coins >= l.coins && r.shells >= l.shells }
    private static func win(_ r: inout RunState, save: inout SaveEnvelope) { r.phase = .won; save.completed.insert(r.level); save.wins += 1; if r.remaining >= 3 { save.medals.insert(r.level) } }
    static func validate(_ s: SaveEnvelope) throws {
        guard s.version == 1, s.completed.allSatisfy({ Content.levels.indices.contains($0) }), s.medals.isSubset(of: s.completed), (0...2).contains(s.settings.skin), [s.totalSpins,s.totalWood,s.totalCrafts,s.wins].allSatisfy({ (0...100_000_000).contains($0) }) else { throw GameError.invalidSave }
        if let r = s.run {
            guard r.mechanicsVersion == nil || r.mechanicsVersion == 1,
                  r.freeRefits == nil || (0...1).contains(r.freeRefits!),
                  r.mechanicsVersion != nil || r.freeRefits == nil else { throw GameError.invalidSave }
            guard Content.levels.indices.contains(r.level), [r.wood,r.coins,r.shells,r.spins,r.boost,r.coinBoost,r.shellBoost,r.remaining,r.crafts].allSatisfy({ (0...100_000).contains($0) }), r.wheel.count == 8, r.wheel.allSatisfy({ (0...3).contains($0.value) }), r.pending.map({ (0..<8).contains($0.index) }) ?? true, r.lastResult.map({ (0..<8).contains($0.index) }) ?? true, r.phase != .upgrade || (r.offers.count == 3 && Set(r.offers).count == 3), r.phase != .ready || r.remaining > 0, r.phase != .lost || r.remaining == 0, r.phase != .won || (meetsGoal(r) && s.completed.contains(r.level)) else { throw GameError.invalidSave }
        }
    }
}
