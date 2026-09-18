import Foundation

/// All reads and writes are serialized. A candidate is published only after its atomic write succeeds.
final class SaveRepository {
    private let directory: URL
    private let queue = DispatchQueue(label: "island.save")
    private var primary: URL { directory.appendingPathComponent("progress.json") }
    private var backup: URL { directory.appendingPathComponent("progress.backup.json") }
    init(directory: URL) { self.directory = directory }
    #if DEBUG
    var testFailure: String?
    private func failIfRequested(_ operation: String) throws {
        if testFailure == operation { throw CocoaError(.fileWriteNoPermission) }
    }
    #endif
    func load() throws -> (SaveEnvelope, String?) {
        try queue.sync {
            #if DEBUG
            try failIfRequested("load")
            #endif
            let fm = FileManager.default
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            if !fm.fileExists(atPath: primary.path) && !fm.fileExists(atPath: backup.path) { return (SaveEnvelope(), nil) }
            for file in [primary, backup] {
                guard let data = try? Data(contentsOf: file) else { continue }
                // Never downgrade or overwrite a save created by a newer application.
                if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let version = object["version"] as? Int, version > 1 { throw GameError.invalidSave }
                if let save = try? JSONDecoder().decode(SaveEnvelope.self, from: data), (try? GameEngine.validate(save)) != nil {
                    if file == backup { try data.write(to: primary, options: .atomic) }
                    return (save, file == backup ? "Your main save could not be read. The last valid backup has been restored." : nil)
                }
            }
            // Preserve unreadable data for diagnostics before starting a clean local game.
            for file in [primary, backup] where fm.fileExists(atPath: file.path) {
                try fm.moveItem(at: file, to: directory.appendingPathComponent("damaged-\(UUID().uuidString).json"))
            }
            return (SaveEnvelope(), "Neither save could be read. The damaged files were preserved and a new island was started.")
        }
    }
    func write(_ save: SaveEnvelope) throws {
        try queue.sync {
            #if DEBUG
            try failIfRequested("write")
            #endif
            try GameEngine.validate(save)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(save)
            if let old = try? Data(contentsOf: primary), let valid = try? JSONDecoder().decode(SaveEnvelope.self, from: old), (try? GameEngine.validate(valid)) != nil { try old.write(to: backup, options: .atomic) }
            try data.write(to: primary, options: .atomic)
        }
    }
    func reset() throws {
        // Write both files: a later backup recovery must not resurrect erased progress.
        try queue.sync {
            #if DEBUG
            try failIfRequested("reset")
            #endif
            let fm = FileManager.default
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            // Clean only our quarantined files. Fail before replacing active saves if cleanup fails.
            for file in try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isRegularFileKey]) {
                let name = file.deletingPathExtension().lastPathComponent
                guard file.pathExtension == "json", name.hasPrefix("damaged-"),
                      UUID(uuidString: String(name.dropFirst("damaged-".count))) != nil,
                      try file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else { continue }
                try fm.removeItem(at: file)
            }
            let data = try JSONEncoder().encode(SaveEnvelope())
            try data.write(to: backup, options: .atomic)
            try data.write(to: primary, options: .atomic)
        }
    }
}
