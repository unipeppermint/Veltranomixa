import XCTest
@testable import IslandCore

struct FixedRandom: RandomSource { var value: Int; mutating func nextIndex() -> Int { value } }
final class GameEngineTests: XCTestCase {
    func new(_ level: Int = 0) throws -> SaveEnvelope { var s = SaveEnvelope(); s.completed = Set(0..<level); try GameEngine.start(level, in: &s); return s }
    func spin(_ s: inout SaveEnvelope, _ index: Int) throws { var rng = FixedRandom(value:index); try GameEngine.spin(&s, random:&rng) }
    func ack(_ s: inout SaveEnvelope) throws { try GameEngine.acknowledge(&s, id:s.run!.pending!.id) }
    func testAllEightBaseOutcomes() throws {
        for i in 0..<8 { var s = try new(); try spin(&s,i); XCTAssertEqual(s.run!.remaining,11); XCTAssertEqual(s.run!.pending!.index,i); XCTAssertEqual(s.run!.wood,[2,0,1,0,1,0,0,0][i]); XCTAssertEqual(s.run!.coins,[0,2,0,0,0,1,0,3][i]) }
    }
    func testAddBeforeMultiplyAndWindConsumption() throws {
        var s = try new(); s.run!.boost = 2; s.run!.doubleNext = true; try spin(&s,0); XCTAssertEqual(s.run!.wood,8); XCTAssertFalse(s.run!.doubleNext)
    }
    func testWindDoesNotStackAndChestDoesNotConsume() throws {
        var s = try new(); s.run!.doubleNext = true; try spin(&s,3); try ack(&s); XCTAssertTrue(s.run!.doubleNext); try spin(&s,6); XCTAssertTrue(s.run!.doubleNext)
    }
    func testFinalSpinUpgradeCanRescue() throws {
        var s = try new(); s.run!.remaining = 1; s.run!.spins = 2; try spin(&s,1); XCTAssertEqual(s.run!.phase,.upgrade); try ack(&s); try GameEngine.choose(.reserve,in:&s); XCTAssertEqual(s.run!.phase,.ready); XCTAssertEqual(s.run!.remaining,2)
    }
    func testWinningTakesPriorityAndIsIdempotent() throws {
        var s = try new(); s.run!.remaining = 1; s.run!.spins = 2; s.run!.wood = 18; try spin(&s,0); XCTAssertEqual(s.run!.phase,.won); XCTAssertEqual(s.wins,1); let id = s.run!.pending!.id
        XCTAssertThrowsError(try spin(&s,0)); try GameEngine.acknowledge(&s,id:id); XCTAssertThrowsError(try GameEngine.acknowledge(&s,id:id)); XCTAssertEqual(s.wins,1)
    }
    func testLastSpinNonRescueLoses() throws {
        var s = try new(); s.run!.remaining = 1; try spin(&s,6); try ack(&s); try GameEngine.choose(.tools,in:&s); XCTAssertEqual(s.run!.phase,.lost)
    }
    func testCraftFundsAndReplacement() throws {
        var s = try new(5); s.run!.freeRefits = 0; XCTAssertThrowsError(try GameEngine.craft(&s)); s.run!.coins = 10; try GameEngine.craft(&s); XCTAssertEqual(s.run!.coins,6); XCTAssertEqual(s.run!.boost,1); try GameEngine.craft(&s,replacing:7,with:.shell); XCTAssertEqual(s.run!.coins,0); XCTAssertEqual(s.run!.wheel[7].kind,.shell)
    }
    func testCombinedUpgradeOnlyOnce() throws {
        var s = try new(); s.run!.spins = 2; try spin(&s,6); try ack(&s); try GameEngine.choose(.tools,in:&s); XCTAssertThrowsError(try GameEngine.choose(.tools,in:&s)); XCTAssertEqual(s.run!.boost,1)
    }
    func testPersistPendingWithoutReaward() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString); defer { try? FileManager.default.removeItem(at:dir) }; let repo = SaveRepository(directory:dir)
        var s = try new(); try spin(&s,0); try repo.write(s); var recovered = try repo.load().0; XCTAssertEqual(recovered.run!.pending,s.run!.pending); try ack(&recovered); XCTAssertEqual(recovered.run!.wood,2); try repo.write(recovered); XCTAssertNil(try repo.load().0.run!.pending)
    }
    func testBackupCorruptionAndReset() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString); defer { try? FileManager.default.removeItem(at:dir) }; let repo = SaveRepository(directory:dir)
        var s = try new(); try repo.write(s); s.run!.wood = 4; try repo.write(s); try Data("broken".utf8).write(to:dir.appendingPathComponent("progress.json")); let recovered = try repo.load(); XCTAssertNotNil(recovered.1); XCTAssertEqual(recovered.0.run!.wood,0); try repo.reset(); XCTAssertNil(try repo.load().0.run)
    }
    func testInvalidVersionAndWriteFailure() throws {
        var s = try new(); s.version = 2; XCTAssertThrowsError(try GameEngine.validate(s)); s.version = 1
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString); defer { try? FileManager.default.removeItem(at:file) }; try Data().write(to:file); XCTAssertThrowsError(try SaveRepository(directory:file).write(s))
    }
    func testContentValidationAndUnlocks() throws {
        XCTAssertEqual(Set(Content.levels.map(\.id)).count,15); XCTAssertEqual(Upgrade.allCases.count,15)
        for l in Content.levels { XCTAssertEqual(l.wheel.count,8); var s = try new(l.id); try GameEngine.validate(s); s.run!.wood = 100; s.run!.coins = 100; s.run!.shells = 100; try spin(&s,0); XCTAssertTrue(s.completed.contains(l.id)) }
        var s = SaveEnvelope(); XCTAssertThrowsError(try GameEngine.start(1,in:&s))
    }
    func testShellAndSupplyPreserveBreeze() throws {
        var s = try new(10); s.run!.doubleNext = true; try spin(&s,5); XCTAssertEqual(s.run!.shells,2); XCTAssertTrue(s.run!.doubleNext); try ack(&s); let remaining = s.run!.remaining; try spin(&s,7); XCTAssertEqual(s.run!.remaining,remaining); XCTAssertEqual(s.run!.wood,1); XCTAssertTrue(s.run!.doubleNext)
    }
}

extension GameEngineTests {
    func testFutureSaveIsNeverOverwritten() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString); defer { try? FileManager.default.removeItem(at:dir) }; let repo = SaveRepository(directory:dir)
        try repo.write(try new()); let file = dir.appendingPathComponent("progress.json"); let data = Data("{\"version\":99}".utf8); try data.write(to:file)
        XCTAssertThrowsError(try repo.load()); XCTAssertEqual(try Data(contentsOf:file),data)
    }
    func testBothCorruptedFilesArePreserved() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString); defer { try? FileManager.default.removeItem(at:dir) }; let repo = SaveRepository(directory:dir)
        try repo.write(try new()); try repo.write(try new())
        for name in ["progress.json","progress.backup.json"] { try Data("bad".utf8).write(to:dir.appendingPathComponent(name)) }
        let loaded = try repo.load(); XCTAssertNil(loaded.0.run); XCTAssertNotNil(loaded.1)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:dir.path).filter { $0.hasPrefix("damaged-") }.count,2)
    }
    func testOffersAndInvalidState() throws {
        var s = try new(); s.run!.phase = .upgrade; s.run!.offers = [.tools,.breeze,.reserve]
        XCTAssertThrowsError(try GameEngine.choose(.festival,in:&s)); try GameEngine.choose(.tools,in:&s)
        s.run!.phase = .won; XCTAssertThrowsError(try GameEngine.validate(s))
    }
}


extension GameEngineTests {
    func testFreeRefitIsConsumedOnceAndPersists() throws {
        var s = try new()
        XCTAssertThrowsError(try GameEngine.craft(&s, replacing: 0, with: .wood))
        XCTAssertEqual(s.run!.freeRefits, 1)
        try GameEngine.craft(&s, replacing: 1, with: .wood)
        XCTAssertEqual(s.run!.probability(.wood), 50)
        XCTAssertEqual(s.run!.coins, 0)
        XCTAssertEqual(s.run!.freeRefits, 0)
        s = try JSONDecoder().decode(SaveEnvelope.self, from: JSONEncoder().encode(s))
        XCTAssertThrowsError(try GameEngine.craft(&s, replacing: 5, with: .wood))
        s.run!.coins = 6
        try GameEngine.craft(&s, replacing: 5, with: .wood)
        XCTAssertEqual(s.run!.coins, 0)
        XCTAssertEqual(s.run!.probability(.wood), 62.5)
    }
    func testGroveWraparoundAndWindOrder() throws {
        var s = try new(3)
        try GameEngine.craft(&s, replacing: 7, with: .wood)
        s.run!.boost = 1; s.run!.doubleNext = true
        XCTAssertEqual(s.run!.yield(at: 0, spinNumber: 1), 8)
        try spin(&s, 0)
        XCTAssertEqual(s.run!.wood, 8)
        XCTAssertFalse(s.run!.doubleNext)
    }
    func testTidePreviewMatchesAwardAndCycleSurvivesReload() throws {
        var s = try new(5)
        try spin(&s, 0); XCTAssertEqual(s.run!.wood, 3); try ack(&s)
        try spin(&s, 1); try ack(&s)
        s = try JSONDecoder().decode(SaveEnvelope.self, from: JSONEncoder().encode(s))
        XCTAssertTrue(s.run!.ruleStatus.contains("涨潮"))
        XCTAssertEqual(s.run!.yield(at: 5, spinNumber: 3), 5)
        s.run!.doubleNext = true
        try spin(&s, 5)
        XCTAssertEqual(s.run!.shells, 5)
        XCTAssertTrue(s.run!.doubleNext)
    }
    func testMarketAlternatesWithoutChangingOdds() throws {
        var s = try new(2)
        try spin(&s, 0); XCTAssertEqual(s.run!.wood, 4); try ack(&s)
        try spin(&s, 1); XCTAssertEqual(s.run!.coins, 4)
        XCTAssertEqual(s.run!.probability(.coin), 37.5)
    }
    func testLegacySaveRetainsClassicRulesAndPaidRefits() throws {
        var s = try new(3)
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as! [String: Any]
        var run = json["run"] as! [String: Any]
        run.removeValue(forKey: "mechanicsVersion"); run.removeValue(forKey: "freeRefits")
        json["run"] = run
        s = try JSONDecoder().decode(SaveEnvelope.self, from: JSONSerialization.data(withJSONObject: json))
        try GameEngine.validate(s)
        XCTAssertNil(s.run!.mechanicsVersion)
        XCTAssertEqual(s.run!.replacementCost, 6)
        s.run!.wheel[7] = Segment(kind: .wood, value: 2)
        try spin(&s, 0); XCTAssertEqual(s.run!.wood, 2)
        try GameEngine.start(3, in: &s)
        XCTAssertEqual(s.run!.rule, .grove)
        XCTAssertEqual(s.run!.freeRefits, 1)
    }
    func testOffersSupportUnfinishedGoalAndAreAffordable() throws {
        var s = try new(2); s.run!.spins = 2
        try spin(&s, 3)
        XCTAssertEqual(s.run!.offers.first, .purse)
        XCTAssertEqual(Set(s.run!.offers).count, 3)
        XCTAssertFalse(s.run!.offers.contains(.exchange))
        var shells = try new(5); shells.run!.wood = 12; shells.run!.spins = 2
        try spin(&shells, 3)
        XCTAssertEqual(shells.run!.offers.first, .shellwork)
    }
}
