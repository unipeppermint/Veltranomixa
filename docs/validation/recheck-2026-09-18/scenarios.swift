import Foundation
struct Fixed: RandomSource { mutating func nextIndex() -> Int { 6 } }
@main struct Audit {
 static func main() throws {
  var s = SaveEnvelope(); try GameEngine.start(0, in: &s)
  var rng = Fixed(); try GameEngine.spin(&s, random: &rng)
  try GameEngine.acknowledge(&s, id: s.run!.pending!.id)
  try GameEngine.choose(.tools, in: &s)
  print("After choosing Better Tools: boost=\(s.run!.boost), displayed upgrades/swaps counter=\(s.run!.crafts)")
  let dir = FileManager.default.temporaryDirectory.appendingPathComponent("lucky-recheck-" + UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: dir) }
  let repo = SaveRepository(directory: dir); try repo.write(s)
  try Data("{\"version\":2}".utf8).write(to: dir.appendingPathComponent("progress.json"))
  do { _ = try repo.load(); print("Unexpected successful future save load") }
  catch { print("Future-version load rejected: \(error.localizedDescription); controller sets loadBlocked and Reset progress returns without feedback.") }
 }
}
