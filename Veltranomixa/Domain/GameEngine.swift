import Foundation

enum Tile: String, Codable, CaseIterable {
    case wood, coin, chest, wind, shell, supply
    var title: String { ["wood":"木材", "coin":"金币", "chest":"宝箱", "wind":"顺风", "shell":"贝壳", "supply":"补给"][rawValue]! }
    var symbol: String { ["wood":"leaf.fill", "coin":"dollarsign.circle.fill", "chest":"shippingbox.fill", "wind":"wind", "shell":"fan.fill", "supply":"ticket.fill"][rawValue]! }
}
struct Segment: Codable, Equatable { var kind: Tile; var value: Int }
enum IslandRule: String {
    case calm, grove, tide, market
    var title: String {
        switch self { case .calm: return "自由工坊"; case .grove: return "林地连携"; case .tide: return "潮汐节律"; case .market: return "轮换集市" }
    }
    var detail: String {
        switch self {
        case .calm: return "每局首次换格免费。多放一格目标资源，命中率增加 12.5 个百分点。"
        case .grove: return "抽中木材时，每个相邻木材格额外提供 1 木材，再计算顺风。首尾格也相邻。"
        case .tide: return "每第 3 转涨潮：贝壳产出 +3；其余转退潮：木材产出 +1，再计算顺风。"
        case .market: return "奇数转木材产出 +2，偶数转金币产出 +2，再计算顺风。换格时要兼顾两种资源。"
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
    var target: String { [(wood > 0 ? "木材 \(wood)" : nil), (coins > 0 ? "金币 \(coins)" : nil), (shells > 0 ? "贝壳 \(shells)" : nil)].compactMap { $0 }.joined(separator: " · ") }
    var reward: String { Content.buildings[min(id, 11)] }
    var wheel: [Segment] {
        var tiles: [Segment] = [.init(kind: .wood, value: 2), .init(kind: .coin, value: 2), .init(kind: .wood, value: 1), .init(kind: .wind, value: 0), .init(kind: .wood, value: 1), .init(kind: .coin, value: 1), .init(kind: .chest, value: 0), .init(kind: .coin, value: 3)]
        if id >= 5 { tiles[5] = .init(kind: .shell, value: 2) }
        if id >= 10 { tiles[7] = .init(kind: .supply, value: 1) }
        return tiles
    }
}
enum Content {
    static let regions = ["海风港湾", "花语丘陵", "星光海岸"]
    static let buildings = ["海岸灯塔", "海边小屋", "渔人木屋", "海风花园", "溪流木桥", "远航帆船", "山丘风车", "许愿喷泉", "甜橙果树", "玻璃花房", "观星望台", "星光灯串"]
    static let levels: [Level] = [
        .init(id: 0, name: "点亮灯塔", story: "让第一束光，照亮归来的小船。", wood: 20, coins: 0, shells: 0, turns: 12),
        .init(id: 1, name: "海边安家", story: "收集木材，也为新家留一点金币。", wood: 16, coins: 5, shells: 0, turns: 14),
        .init(id: 2, name: "渔人的清晨", story: "金币用于添置渔具，改造前记得留够。", wood: 0, coins: 18, shells: 0, turns: 13),
        .init(id: 3, name: "花开港湾", story: "在有限的机会里，为花园搭好围栏。", wood: 24, coins: 0, shells: 0, turns: 12),
        .init(id: 4, name: "搭一座桥", story: "连接港湾与山丘，准备两种资源。", wood: 22, coins: 8, shells: 0, turns: 16),
        .init(id: 5, name: "贝壳来信", story: "贝壳格加入转盘，收集来自海洋的礼物。", wood: 12, coins: 0, shells: 4, turns: 16),
        .init(id: 6, name: "风车慢慢转", story: "借着顺风，让每一块木材发挥作用。", wood: 28, coins: 0, shells: 0, turns: 14),
        .init(id: 7, name: "泉水的愿望", story: "金币与贝壳，换来一池清澈的水。", wood: 0, coins: 14, shells: 4, turns: 18),
        .init(id: 8, name: "橙子的季节", story: "种一棵树，等一阵海风。", wood: 20, coins: 6, shells: 2, turns: 17),
        .init(id: 9, name: "透明的花房", story: "平衡改造投入与三种建设材料。", wood: 24, coins: 8, shells: 4, turns: 20),
        .init(id: 10, name: "抬头看星星", story: "补给格会返还一次机会，再送一块木材。", wood: 30, coins: 0, shells: 4, turns: 17),
        .init(id: 11, name: "今晚有灯会", story: "用贝壳点缀海岸，点亮温暖的灯串。", wood: 18, coins: 0, shells: 8, turns: 20),
        .init(id: 12, name: "珊瑚色日落", story: "完成挑战，收藏珊瑚转盘外观。", wood: 32, coins: 8, shells: 0, turns: 18),
        .init(id: 13, name: "潮汐的礼物", story: "为星夜转盘收集海洋珍藏。", wood: 0, coins: 12, shells: 10, turns: 22),
        .init(id: 14, name: "小岛的庆典", story: "三片区域的最后一站，让幸运留下风景。", wood: 32, coins: 10, shells: 8, turns: 24)
    ]
}
enum Upgrade: String, Codable, CaseIterable {
    case tools, breeze, reserve, purse, shellwork, timber, savings, beach, exchange, workshop, sail, tide, bundle, compass, festival
    var title: String { ["加固工具","顺风时刻","备用机会","金币模具","贝壳工艺","漂流木","储蓄罐","沙滩漫步","以金换木","工坊礼包","轻帆启航","潮汐馈赠","满载而归","航海罗盘","庆典礼物"][Self.allCases.firstIndex(of: self)!] }
    var detail: String { ["所有木材格产出 +1，可叠加","下次木材或金币翻倍，不叠加","增加 2 次转动","所有金币格产出 +1","所有贝壳格产出 +1","立即获得 5 木材","立即获得 4 金币","立即获得 3 贝壳","消耗 3 金币，获得 8 木材","木材格 +1，立即获得 1 金币","增加 1 次转动，并获得顺风","获得 2 贝壳和 2 金币","获得 3 木材和 2 金币","增加 1 次转动和 2 木材","获得 2 木材、2 金币、1 贝壳"][Self.allCases.firstIndex(of: self)!] }
}
enum Phase: String, Codable { case ready, upgrade, won, lost }
struct SpinRecord: Codable, Equatable { let id: UUID; let index: Int; let message: String }
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
        guard mechanicsVersion == 1 else { return "经典规则 · 当前对局保持原有玩法" }
        switch rule {
        case .calm: return (freeRefits ?? 0) > 0 ? "自由工坊 · 首次换格免费" : "自由工坊 · 换格调概率，强化提产出"
        case .grove: return "林地连携 · 相邻木材格各加成 +1"
        case .tide: return (spins + 1) % 3 == 0 ? "下一转涨潮 · 贝壳 +3" : "下一转退潮 · 木材 +1 · 距涨潮 \(3 - spins % 3) 转"
        case .market: return (spins + 1) % 2 == 1 ? "下一转木材集市 · 木材 +2" : "下一转金币集市 · 金币 +2"
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
    static let achievementNames = ["第一束光", "转动的时光", "木材收藏家", "小岛工匠", "策略探索者", "六种幸运", "港湾建造者", "山丘守护者", "从容不迫", "小岛的庆典"]
    static let achievementDetails = ["完成首个关卡", "累计转动 25 次", "累计收集 100 木材", "累计改造 5 次", "选择 5 种升级", "遇见全部 6 种格子", "完成 5 个关卡", "完成 10 个关卡", "3 关完成额外挑战", "完成全部 15 关"]
}
protocol RandomSource { mutating func nextIndex() -> Int }
struct SystemRandomSource: RandomSource { mutating func nextIndex() -> Int { Int.random(in: 0..<8) } }
enum GameError: LocalizedError {
    case invalidAction, insufficientCoins, invalidSave
    var errorDescription: String? { switch self { case .invalidAction: return "当前操作不可用，请先完成转动或升级。"; case .insufficientCoins: return "金币不足，再收集一些吧。"; case .invalidSave: return "存档格式或数据不兼容。" } }
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
        case .chest: message = "发现宝箱，选择一次升级"
        case .wind: r.doubleNext = true; message = "顺风就绪，下次木材或金币翻倍"
        case .shell: let amount = r.yield(at: index, spinNumber: r.spins); r.shells += amount; message = "贝壳 +\(amount)"
        case .supply: r.remaining += 1; r.wood += 1; message = "补给：机会 +1，木材 +1"
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
