import UIKit
import SnapKit

final class ViewController: UIViewController {
    enum Page { case island, levels, game, workshop, collection, settings }
    private var page: Page = .island
    private var state = SaveEnvelope()
    private var repository: SaveRepository!
    private var stack = UIStackView()
    private var scroll = UIScrollView()
    private var wheel: WheelView?
    private var busy = false
    private var loadBlocked = false
    private var notice: String?
    private var latestMessage = "Shape your wheel. Plan your next spin."
    private var selectedUpgrade: Upgrade?
    private var selectedSlot = 1
    private var selectedKind: Tile = .wood
    override func viewDidLoad() {
        super.viewDidLoad(); overrideUserInterfaceStyle = .light
        var directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("LuckyIsland", isDirectory: true)
        #if DEBUG
        if ProcessInfo.processInfo.environment["ISLAND_UI_TEST_SESSION"] == "1" {
            directory = directory.appendingPathComponent("UITests", isDirectory: true)
        }
        #endif
        repository = SaveRepository(directory: directory)
        do { (state, notice) = try repository.load() } catch { loadBlocked = true; notice = "Unable to load your save: \(error.localizedDescription) Your progress is protected. Saving is temporarily unavailable." }
        NotificationCenter.default.addObserver(self, selector: #selector(background), name: UIApplication.didEnterBackgroundNotification, object: nil)
        render()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let notice { self.notice = nil; info("Save notice", notice) }
        else if !state.settings.tutorialSeen { tutorial() }
    }
    @objc private func background() { Feedback.shared.stop() }
    private func commit(_ change: (inout SaveEnvelope) throws -> Void) -> Bool {
        guard !loadBlocked else { info("Save unavailable", "Please reopen the app and try again. Your existing save has not been overwritten."); return false }
        do { var next = state; try change(&next); try repository.write(next); state = next; return true }
        catch { info("Action not completed", "\(error.localizedDescription)\nYour progress has not changed. Please try again."); return false }
    }
    private func go(_ destination: Page) { guard !busy else { return }; page = destination; render() }
    private func render() {
        view.subviews.forEach { $0.removeFromSuperview() }; wheel = nil
        view.backgroundColor = UIColor(red: 0.83, green: 0.95, blue: 0.93, alpha: 1)
        let gradient = CAGradientLayer(); gradient.colors = [UIColor(red: 0.57, green: 0.86, blue: 0.96, alpha: 1).cgColor, Theme.cream.cgColor]; gradient.frame = view.bounds
        view.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }; view.layer.insertSublayer(gradient, at: 0)
        scroll = UIScrollView(); scroll.alwaysBounceVertical = true; scroll.showsVerticalScrollIndicator = false; view.addSubview(scroll)
        let nav = UIStackView(); nav.distribution = .fillEqually; nav.spacing = 6
        if page != .game && page != .workshop {
            for (title, symbol, destination) in [("Island","house.fill", Page.island),("Collection","star.fill",Page.collection),("Settings","gearshape.fill",Page.settings)] {
                let b = Theme.button(title, symbol: symbol) { [weak self] in self?.go(destination) }; b.accessibilityIdentifier = "tab.\(title)"
                var config = b.configuration!; config.imagePlacement = .top; config.imagePadding = 4
                config.contentInsets = .init(top: 8, leading: 6, bottom: 8, trailing: 6)
                config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
                config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { var a = $0; a.font = .systemFont(ofSize: 13, weight: .bold); return a }
                b.configuration = config; nav.addArrangedSubview(b)
            }
            view.addSubview(nav); nav.snp.makeConstraints { $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16); $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(4) }
        }
        scroll.snp.makeConstraints { $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide); if page == .game || page == .workshop { $0.bottom.equalTo(view.safeAreaLayoutGuide) } else { $0.bottom.equalTo(nav.snp.top).offset(-8) } }
        stack = Theme.stack([], spacing: 16); scroll.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalTo(scroll.contentLayoutGuide).inset(20); $0.width.equalTo(scroll.frameLayoutGuide).offset(-40) }
        switch page { case .island: island(); case .levels: levels(); case .game: game(); case .workshop: workshop(); case .collection: collection(); case .settings: settings() }
    }
    private func add(_ v: UIView) { stack.addArrangedSubview(v) }
    private func heading(_ eyebrow: String, _ title: String, _ subtitle: String? = nil) {
        let eyebrowLabel = Theme.label(eyebrow, size: 12, color: Theme.teal)
        let titleLabel = Theme.label(title, size: 30)
        if [.island, .levels, .collection, .settings].contains(page) {
            let row = UIStackView(); row.axis = .horizontal; row.alignment = .center; row.spacing = 12
            let largeText = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
            if !largeText { add(eyebrowLabel) }
            row.addArrangedSubview(largeText ? eyebrowLabel : titleLabel)
            let decoration = UIImageView(image: WheelDecoration.image)
            decoration.contentMode = .scaleAspectFit
            decoration.isAccessibilityElement = false
            decoration.isUserInteractionEnabled = false
            row.addArrangedSubview(decoration)
            let size: CGFloat = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 54 : 76
            decoration.snp.makeConstraints { $0.width.height.equalTo(size) }
            add(row)
            if largeText { add(titleLabel) }
        } else {
            add(eyebrowLabel); add(titleLabel)
        }
        if let subtitle { add(Theme.label(subtitle, size: 15, color: Theme.ink.withAlphaComponent(0.65))) }
    }
    private func island() {
        heading("BUILD YOUR OWN LITTLE WORLD", "Lucky Island", "Shape your wheel, follow the tides, and build an island with every choice.")
        let scene = IslandView(completed: state.completed); add(scene); scene.snp.makeConstraints { $0.height.equalTo(scene.snp.width).multipliedBy(0.80) }
        let levelID = min((0..<15).first(where: { !state.completed.contains($0) }) ?? 14, 14)
        let l = Content.levels[levelID]
        let content = Theme.stack([Theme.label("\(Content.regions[l.region])  ·  \(state.completed.count)/15", size: 13, color: Theme.teal), Theme.label("Next stop: \(l.name)", size: 22), Theme.label(l.story, size: 15)])
        if let r = state.run, r.phase == .ready || r.phase == .upgrade || r.pending != nil {
            content.addArrangedSubview(Theme.button("Continue · \(Content.levels[r.level].name)", symbol: "play.fill", primary: true) { [weak self] in self?.go(.game) })
        } else {
            content.addArrangedSubview(Theme.button("Start challenge", symbol: "arrow.right", primary: true) { [weak self] in self?.detail(levelID) })
        }
        add(Theme.card(content)); add(Theme.button("Explore the island", symbol: "map") { [weak self] in self?.go(.levels) })
    }
    private func levels() {
        heading("ONE ISLAND. FIFTEEN LITTLE STORIES.", "Island map")
        for region in 0..<3 {
            add(Theme.label(Content.regions[region], size: 22))
            for l in Content.levels where l.region == region {
                let unlocked = l.id == 0 || state.completed.contains(l.id - 1)
                let b = Theme.button("\(String(format: "%02d", l.id + 1))  \(l.name)\(state.medals.contains(l.id) ? "  ★" : "")", symbol: state.completed.contains(l.id) ? "checkmark.seal.fill" : (unlocked ? "flag.fill" : "lock.fill")) { [weak self] in self?.detail(l.id) }
                b.isEnabled = unlocked; add(b)
            }
        }
    }
    private func detail(_ id: Int) {
        let l = Content.levels[id]
        let reward = id < 12 ? Content.buildings[id] : (id == 12 ? "Coral wheel" : (id == 13 ? "Starlight wheel" : "Island Festival achievement"))
        let a = UIAlertController(title: l.name, message: "\(l.story)\n\nGoal: \(l.target)\nIsland rule: \(l.rule.title)\n\(l.rule.detail)\nStarting spins: \(l.turns)\nUnlock: \(reward)\nBonus challenge: win with at least 3 spins left.\n\n\(state.run != nil ? "Starting a new challenge replaces your current run. Your collection is kept." : "Choose an upgrade every 3 spins or when you land on a chest.")", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Start challenge", style: .default) { [weak self] _ in
            guard let self else { return }; if self.commit({ try GameEngine.start(id, in: &$0) }) { self.latestMessage = "Plan your next spin in the workshop."; self.go(.game) }
        }); a.addAction(UIAlertAction(title: "Not now", style: .cancel)); present(a, animated: true)
    }
    private func game() {
        guard let r = state.run else { page = .island; island(); return }
        stack.spacing = 12
        let header = UIStackView(); header.spacing = 10; header.alignment = .center
        let back = Theme.button("", symbol: "chevron.left") { [weak self] in self?.go(.island) }
        let help = Theme.button("", symbol: "questionmark") { [weak self] in self?.rules() }
        back.accessibilityLabel = "Island"; help.accessibilityLabel = "Rules"
        for button in [back, help] {
            var config = button.configuration!
            config.contentInsets = .init(top: 12, leading: 10, bottom: 12, trailing: 10)
            button.configuration = config
            button.snp.makeConstraints { $0.width.equalTo(48) }
        }
        let title = Theme.label(Content.levels[r.level].name, size: 21); title.textAlignment = .center
        header.addArrangedSubview(back); header.addArrangedSubview(title); header.addArrangedSubview(help); add(header)
        if r.pending == nil && r.phase == .upgrade { upgrades(r); return }
        if r.pending == nil && (r.phase == .won || r.phase == .lost) { result(r); return }
        #if DEBUG
        if ProcessInfo.processInfo.environment["ISLAND_UI_FIXED_WOOD"] == "1" { add(Theme.label("UI TEST MODE · FIXED RESULT", size: 12, color: .systemRed)) }
        #endif
        let l = Content.levels[r.level]
        let progress = Theme.stack([], spacing: 8)
        for (title, value, goal) in [("Wood",r.wood,l.wood),("Coins",r.coins,l.coins),("Shells",r.shells,l.shells)] where goal > 0 {
            progress.addArrangedSubview(Theme.label("\(title)  \(value) / \(goal)", size: 20))
            let bar = UIProgressView(progressViewStyle: .default); bar.progressTintColor = Theme.teal; bar.trackTintColor = Theme.ink.withAlphaComponent(0.1); bar.progress = min(1, Float(value)/Float(goal)); bar.accessibilityLabel = title; bar.accessibilityValue = "\(value) of \(goal)"; progress.addArrangedSubview(bar)
        }
        progress.addArrangedSubview(Theme.label(r.ruleStatus, size: 14, color: Theme.teal))
        add(Theme.card(progress))
        let stats = Theme.label("Coins \(r.coins)    ·    Spins left \(r.remaining)\(r.level >= 5 ? "    ·    Shells \(r.shells)" : "")", size: 17); stats.textAlignment = .center; add(stats)
        let wheelContainer = UIView(); add(wheelContainer)
        let w = WheelView(run: r, skin: state.settings.skin); wheel = w; wheelContainer.addSubview(w)
        w.snp.makeConstraints {
            $0.top.bottom.centerX.equalToSuperview()
            $0.width.lessThanOrEqualToSuperview(); $0.width.equalToSuperview().priority(750)
            $0.width.lessThanOrEqualTo(300); $0.height.equalTo(w.snp.width)
        }
        let msg = Theme.label(r.pending != nil ? "Your spin is saved. Tap to reveal it." : latestMessage, size: 15, color: Theme.teal); msg.textAlignment = .center; msg.accessibilityIdentifier = "game.message"; add(msg)
        if r.doubleNext { let wind = Theme.label("Breeze ready · Next Wood or Coins ×2", size: 14); wind.textAlignment = .center; add(wind) }
        let spin = Theme.button(r.pending == nil ? "Spin the wheel" : "Reveal saved spin", symbol: "sparkles", primary: true) { [weak self] in self?.spin() }; spin.accessibilityIdentifier = "game.spin"; add(spin)
        let craft = Theme.button((r.freeRefits ?? 0) > 0 ? "Free swap · Shape your wheel" : "Wheel workshop", symbol: "hammer.fill") { [weak self] in self?.craft() }; craft.accessibilityIdentifier = "game.workshop"; craft.isEnabled = r.pending == nil; add(craft)
        if (r.freeRefits ?? 0) > 0 { add(Theme.label("Swap a Coins tile for Wood to raise its chance from 37.5% to 50%. Your first swap is free, then 6 coins each.", size: 14, color: Theme.teal)) }
        let caption = Theme.label("8 equal tiles · 12.5% each\nTools +\(r.boost) · Upgrade every 3 spins · This run only", size: 12, color: Theme.ink.withAlphaComponent(0.6)); caption.textAlignment = .center; add(caption)
    }
    private func spin() {
        guard !busy else { return }
        if state.run?.pending == nil {
            #if DEBUG
            if ProcessInfo.processInfo.environment["ISLAND_UI_FIXED_WOOD"] == "1" {
                struct FixedWood: RandomSource {
                    mutating func nextIndex() -> Int {
                        let index = Int(ProcessInfo.processInfo.environment["ISLAND_UI_FIXED_INDEX"] ?? "0") ?? 0
                        return (0..<8).contains(index) ? index : 0
                    }
                }
                var rng = FixedWood()
                guard commit({ try GameEngine.spin(&$0, random: &rng) }) else { return }
            } else {
                var rng = SystemRandomSource()
                guard commit({ try GameEngine.spin(&$0, random: &rng) }) else { return }
            }
            #else
            var rng = SystemRandomSource()
            guard commit({ try GameEngine.spin(&$0, random: &rng) }) else { return }
            #endif
        }
        guard let record = state.run?.pending else { return }
        busy = true; stack.isUserInteractionEnabled = false
        Feedback.shared.play(state.settings)
        let finish: () -> Void = { [weak self] in
            guard let self else { return }; self.busy = false; self.stack.isUserInteractionEnabled = true
            if self.commit({ try GameEngine.acknowledge(&$0, id: record.id) }) {
                self.latestMessage = record.displayMessage; self.render(); self.rewardFlight(record)
                UIAccessibility.post(notification: .announcement, argument: record.displayMessage)
                if self.state.run?.phase == .won { Feedback.shared.play(self.state.settings, success: true) }
            } else { self.render() }
        }
        if let wheel { wheel.spin(to: record.index, duration: (state.settings.fast || UIAccessibility.isReduceMotionEnabled) ? 0.15 : 2.8, completion: finish) } else { finish() }
    }
    private func rewardFlight(_ record: SpinRecord) {
        guard !UIAccessibility.isReduceMotionEnabled, !state.settings.fast, page == .game, let r = state.run, r.phase == .ready else { return }
        let icon = UIImageView(image: Art.item(r.wheel[record.index].kind)); icon.contentMode = .scaleAspectFit
        view.addSubview(icon); icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(64) }
        view.layoutIfNeeded()
        let travel = CAAnimationGroup(); travel.duration = 0.65; travel.isRemovedOnCompletion = true
        let move = CABasicAnimation(keyPath: "transform.translation.y"); move.fromValue = 0; move.toValue = -view.bounds.height * 0.25
        let fade = CABasicAnimation(keyPath: "opacity"); fade.fromValue = 1; fade.toValue = 0
        let scale = CABasicAnimation(keyPath: "transform.scale"); scale.fromValue = 1; scale.toValue = 0.4
        travel.animations = [move, fade, scale]; travel.timingFunction = CAMediaTimingFunction(name: .easeOut)
        CATransaction.begin(); CATransaction.setCompletionBlock { [weak icon] in icon?.removeFromSuperview() }; icon.layer.add(travel, forKey: "reward"); CATransaction.commit()
    }
    private func upgrades(_ r: RunState) {
        heading("GROW, KEEP GOING, OR STOCK UP?", "Choose an upgrade", "\(latestMessage)\n\(r.ruleStatus)\nUpgrades last for this challenge only.")
        let selected = r.offers.contains(selectedUpgrade ?? .tools) ? (selectedUpgrade ?? .tools) : r.offers[0]
        selectedUpgrade = selected
        for upgrade in r.offers {
            let b = Theme.button("\(upgrade.title)\n\(upgrade.detail)", symbol: upgrade == selected ? "checkmark.circle.fill" : "circle") { [weak self] in self?.selectedUpgrade = upgrade; self?.render() }
            var config = b.configuration!
            config.title = upgrade.title; config.subtitle = upgrade.detail
            config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { var a = $0; a.font = Theme.font(14, .regular); return a }
            let kind: Tile = [.breeze,.sail].contains(upgrade) ? .wind : ([.reserve,.compass].contains(upgrade) ? .supply : ([.beach,.shellwork,.tide].contains(upgrade) ? .shell : ([.savings,.purse,.exchange].contains(upgrade) ? .coin : .wood)))
            if let thumb = Art.item(kind)?.preparingThumbnail(of: CGSize(width: 192, height: 192))?.cgImage { config.image = UIImage(cgImage: thumb, scale: 3, orientation: .up) }
            config.titleAlignment = .leading; config.imagePadding = 16
            b.configuration = config; b.layer.cornerRadius = 22; b.layer.borderWidth = upgrade == selected ? 2 : 0
            b.layer.borderColor = Theme.teal.cgColor
            b.accessibilityLabel = "\(upgrade.title), \(upgrade.detail)"
            b.accessibilityTraits = upgrade == selected ? [.button, .selected] : .button; add(b)
        }
        add(Theme.button("Confirm upgrade", primary: true) { [weak self] in
            guard let self, let choice = self.selectedUpgrade else { return }
            if self.commit({ try GameEngine.choose(choice, in: &$0) }) { self.selectedUpgrade = nil; self.latestMessage = "\(choice.title) is now active"; Feedback.shared.play(self.state.settings); self.render() }
        })
        add(Theme.label("Spins left \(r.remaining) · Wood \(r.wood) · Coins \(r.coins)\nEven on your last spin, an upgrade can give you more chances.", size: 14))
    }
    private func result(_ r: RunState) {
        let won = r.phase == .won
        heading(won ? "A LITTLE LUCK. A NEW LANDMARK." : "A FRESH BREEZE. ANOTHER CHANCE.", won ? "\(Content.levels[r.level].name) · Complete" : "So close!", won ? (r.level < 12 ? "Your new landmark is now on your island and in your collection." : (r.level < 14 ? "A new wheel style is in your collection. Visit Wheel styles to equip it." : "Island Festival unlocked. Thank you for bringing this little island to life.")) : "\(Content.levels[r.level].rule.detail) Try a different tile layout next time.")
        if r.level < 12 {
            let art = UIImageView(image: Art.building(r.level)); art.contentMode = .scaleAspectFit; add(art); art.snp.makeConstraints { $0.height.equalTo(220) }
        } else {
            let preview = WheelView(run: r, skin: r.level == 12 ? 1 : 2); add(preview); preview.snp.makeConstraints { $0.height.equalTo(preview.snp.width) }
        }
        add(Theme.card(Theme.stack([Theme.label("Wood \(r.wood)   Coins \(r.coins)   Shells \(r.shells)",size:18), Theme.label("\(r.spins) spins · \(r.crafts) upgrades and swaps",size:15),Theme.label(won && r.remaining >= 3 ? "★ Bonus challenge complete: Room to Spare" : "Bonus: win with at least 3 spins left",size:14)])))
        if won && r.level < 14 { add(Theme.button("Next stop", symbol: "arrow.right", primary: true) { [weak self] in self?.detail(r.level + 1) }) }
        add(Theme.button("Try again", symbol: "arrow.clockwise", primary: !won) { [weak self] in self?.detail(r.level) })
        add(Theme.button("Back to island", symbol: "house.fill") { [weak self] in self?.go(.island) })
    }
    private func craft() {
        guard let r = state.run, r.pending == nil, r.phase == .ready else { return }
        selectedSlot = r.wheel.firstIndex(where: { $0.kind == .coin }) ?? 0
        selectedKind = .wood
        go(.workshop)
    }
    private func refreshWorkshop() {
        let offset = scroll.contentOffset
        render(); view.layoutIfNeeded()
        scroll.setContentOffset(offset, animated: false)
    }
    private func workshop() {
        guard let r = state.run else { go(.island); return }
        add(Theme.button("Back to game", symbol: "chevron.left") { [weak self] in self?.go(.game) })
        heading("EVERY TILE IS A CHOICE.", "Wheel workshop", "Coins \(r.coins) · \(r.ruleStatus)\n\(r.mechanicsVersion == 1 ? Content.levels[r.level].rule.detail : "This run uses classic rules.")")
        if r.canReplace {
            add(Theme.label("1 · Choose a tile", size: 20))
            add(Theme.label("Tiles are numbered 1–8 clockwise from the original top position. Replacing a Chest or Breeze removes its effect.", size: 13))
            var slotRow = UIStackView()
            let columns = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 1 : 2
            for (index, tile) in r.wheel.enumerated() {
                if index % columns == 0 { slotRow = UIStackView(); slotRow.spacing = 8; slotRow.distribution = .fillEqually; add(slotRow) }
                let b = Theme.button("\(index + 1)  \(tile.kind.title) · Base \(tile.value)", symbol: selectedSlot == index ? "checkmark.circle.fill" : "circle") { [weak self] in
                    self?.selectedSlot = index; self?.refreshWorkshop()
                }
                b.accessibilityIdentifier = "workshop.slot.\(index)"; slotRow.addArrangedSubview(b)
            }
            add(Theme.label("2 · Choose a resource", size: 20))
            for kind in r.level >= 5 ? [Tile.wood, .coin, .shell] : [.wood, .coin] {
                let b = Theme.button("\(kind.title) · Base +2", symbol: selectedKind == kind ? "checkmark.circle.fill" : "circle") { [weak self] in
                    self?.selectedKind = kind; self?.refreshWorkshop()
                }
                b.accessibilityIdentifier = "workshop.kind.\(kind.rawValue)"; add(b)
            }
            var preview = r
            preview.wheel[selectedSlot] = Segment(kind: selectedKind, value: 2)
            var lines = ["Tile \(selectedSlot + 1): \(r.wheel[selectedSlot].kind.title) → \(selectedKind.title)"]
            for kind in r.level >= 5 ? [Tile.wood, .coin, .shell] : [.wood, .coin] {
                lines.append("\(kind.title) chance: \(r.probability(kind))% → \(preview.probability(kind))%")
            }
            lines.append("If this tile lands next: +\(preview.yield(at: selectedSlot, spinNumber: r.spins + 1)) \(selectedKind.title) (bonuses included)")
            if r.rule == .grove { lines.append("Neighboring Wood tiles also gain the grove bonus. Tiles 1 and 8 are neighbors.") }
            let level = Content.levels[r.level]
            for (kind, held, target) in [(Tile.wood, r.wood, level.wood), (.coin, r.coins, level.coins), (.shell, r.shells, level.shells)] where held < target && preview.probability(kind) == 0 {
                lines.append("Note: you still need \(kind.title), but this swap removes its last tile.")
            }
            lines.append("Cost: \(r.replacementCost) coins · Balance: \(max(0, r.coins - r.replacementCost))\(level.coins > 0 ? " · Keep \(level.coins) coins to win" : "")")
            let previewLabel = Theme.label(lines.joined(separator: "\n"), size: 15)
            previewLabel.accessibilityIdentifier = "workshop.preview"; add(Theme.card(previewLabel))
            let same = r.wheel[selectedSlot] == preview.wheel[selectedSlot]
            let apply = Theme.button(same ? "This tile already matches" : (r.replacementCost == 0 ? "Confirm free swap" : "Confirm swap · 6 coins"), symbol: "hammer.fill", primary: true) { [weak self] in
                guard let self else { return }; self.buyCraft(index: self.selectedSlot, kind: self.selectedKind)
            }
            apply.accessibilityIdentifier = "workshop.apply"
            apply.isEnabled = !same && r.coins >= r.replacementCost; add(apply)
        }
        add(Theme.label("Or keep your layout and boost its yield", size: 18))
        let reinforce = Theme.button("4 coins · All Wood tiles +1", symbol: "wrench.fill") { [weak self] in self?.buyCraft() }
        reinforce.isEnabled = r.coins >= 4; add(reinforce)
        add(Theme.label("Boosts stack without changing the odds. All changes last for this run only.", size: 13))
    }
    private func buyCraft(index: Int? = nil, kind: Tile = .wood) {
        guard let before = state.run else { return }
        if commit({ try GameEngine.craft(&$0, replacing: index, with: kind) }) {
            latestMessage = index == nil ? "Wood tiles +1. Your layout stays the same." : "\(kind.title) chance \(before.probability(kind))% → \(state.run!.probability(kind))%"
            Feedback.shared.play(state.settings); go(.game)
        }
    }
    private func collection() {
        heading("EVERY LITTLE LUCK LEAVES A MARK.", "Collection", "Landmarks \(state.completed.filter { $0 < 12 }.count)/12 · Achievements \(state.achievements.filter { $0 }.count)/10")
        for i in 0..<12 {
            let unlocked = state.completed.contains(i)
            let row = UIStackView(); row.spacing = 14; row.alignment = .center
            if traitCollection.preferredContentSizeCategory.isAccessibilityCategory { row.axis = .vertical; row.alignment = .leading }
            let image = UIImageView(image: Art.building(i)); image.contentMode = .scaleAspectFit; image.alpha = unlocked ? 1 : 0.28; row.addArrangedSubview(image); image.snp.makeConstraints { $0.width.height.equalTo(82) }
            row.addArrangedSubview(Theme.stack([Theme.label(Content.buildings[i],size:19), Theme.label(unlocked ? "Built · Find it on your island" : "Complete level \(i+1) to unlock", size:13,color:Theme.teal)])); add(Theme.card(row))
        }
        add(Theme.label("Achievements",size:24))
        for (i, achieved) in state.achievements.enumerated() { add(Theme.card(Theme.stack([Theme.label("\(achieved ? "★" : "☆")  \(SaveEnvelope.achievementNames[i])",size:18),Theme.label(SaveEnvelope.achievementDetails[i],size:14)]))) }
        add(Theme.label("Wheel styles",size:24))
        for (i, name) in ["Breeze","Coral","Starlight"].enumerated() {
            let unlocked = i == 0 || state.completed.contains(i == 1 ? 12 : 13)
            let b = Theme.button("\(name)\(state.settings.skin == i ? " · Equipped" : "")\(unlocked ? "" : " · Unlock at level \(i == 1 ? 13 : 14)")",symbol:unlocked ? "circle.lefthalf.filled" : "lock.fill") { [weak self] in guard let self else { return }; if self.commit({ $0.settings.skin = i }) { self.render() } }; b.isEnabled = unlocked; add(b)
        }
    }
    private func settings() {
        heading("ISLAND TIME, AT YOUR OWN PACE.", "Settings")
        for (name,key) in [("Sound effects",0),("Haptics",1),("Quick spins",2)] {
            let row = UIStackView(); row.alignment = .center; row.spacing = 16
            row.addArrangedSubview(Theme.label(name)); let toggle = UISwitch(); toggle.onTintColor = Theme.teal; toggle.isOn = key == 0 ? state.settings.sound : (key == 1 ? state.settings.haptics : state.settings.fast); toggle.accessibilityLabel = name
            toggle.addAction(UIAction { [weak self, weak toggle] _ in guard let self, let toggle else { return }; let on = toggle.isOn; if !self.commit({ if key == 0 { $0.settings.sound = on } else if key == 1 { $0.settings.haptics = on } else { $0.settings.fast = on } }) { toggle.isOn = !on }; if key == 0 && !on { Feedback.shared.stop() } }, for: .valueChanged); row.addArrangedSubview(toggle); add(Theme.card(row))
        }
        add(Theme.button("How to play",symbol:"questionmark.circle") { [weak self] in self?.tutorial() })
        add(Theme.button("Rules and odds",symbol:"info.circle") { [weak self] in self?.rules() })
        add(Theme.button("Privacy and saves",symbol:"lock.shield") { [weak self] in self?.info("Your island stays on your device", "No account, ads, analytics, or servers. The app does not collect or transmit personal information. Progress and settings are saved only on your device, without cloud sync. Deleting the app may erase your progress.\n\nEvery action saves automatically. Leaving during a spin never draws a new result. Turning on Reduce Motion in system settings shortens wheel animations.") })
        add(Theme.button("About Lucky Island",symbol:"info.circle") { [weak self] in
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
            self?.info("Lucky Island · \(version)", "Shape your wheel, gather resources, and turn each choice into a new island landmark.\n\nExplore Breeze Harbor, Blossom Hills, and Starlight Coast. Build your own little island, offline and at your own pace.")
        })
        add(Theme.button("Reset all progress",symbol:"trash") { [weak self] in self?.reset() })
        add(Theme.label("Saved on device · No ads · No purchases",size:13,color:Theme.ink.withAlphaComponent(0.6)))
    }
    private func reset() {
        let a = UIAlertController(title:"Reset your island?",message:"Your current run, all landmarks, and all achievements will be deleted. This cannot be undone.",preferredStyle:.alert)
        a.addAction(UIAlertAction(title:"Reset progress",style:.destructive) { [weak self] _ in guard let self, !self.loadBlocked else { return }; do { try self.repository.reset(); self.state = SaveEnvelope(); self.go(.island) } catch { self.info("Could not reset", error.localizedDescription) } }); a.addAction(UIAlertAction(title:"Keep my island",style:.cancel)); present(a,animated:true)
    }
    private func tutorial() {
        let a = UIAlertController(title:"Welcome to Lucky Island",message:"1. Pick a goal, then try a free tile swap in the workshop. More tiles of a resource means a higher chance of landing on it.\n\n2. Choose an upgrade every 3 spins or from a chest. Tool boosts stack; Breeze does not.\n\n3. Connect Wood tiles in the grove, watch every third spin at high tide, and alternate resources at the market. Meet all goals before your spins run out. Landmarks stay forever; you can always retry.\n\nEvery tile has equal odds. No energy timers. Progress saves automatically.",preferredStyle:.alert)
        a.addAction(UIAlertAction(title:"Let's begin",style:.default) { [weak self] _ in _ = self?.commit { $0.settings.tutorialSeen = true } }); present(a,animated:true)
    }
    private func rules() { info("Fair odds · 12.5% per tile", "All 8 tiles have equal odds, with no hidden adjustments.\n\nWood and Coins: base yield + tools + island bonus, then Breeze doubles the result. Breeze affects only the next Wood or Coins reward. It does not stack, and other tiles do not use it up.\n\nChest: choose one of 3 upgrades. Breeze: prepare a double reward. Shells: base yield + shell tools. Supply: +1 spin and +1 Wood.\n\nUpgrade every 3 spins. A chest on the same spin gives only one choice. On your last spin, check goals first, then upgrades, then remaining spins.\n\nYour first swap is free; later swaps cost 6 coins and create a tile with base yield 2. Spend 4 coins to boost all Wood tiles by 1. The workshop previews odds and next-spin yields.\n\nGrove: +1 Wood per neighboring Wood tile. Tide: +3 Shells every third spin; otherwise +1 Wood. Market: +2 Wood on odd spins, +2 Coins on even spins. Wheel labels show base yield plus tools; the workshop includes all active bonuses. Older runs keep classic rules. Changes last for this run only.\n\nBonus challenge: win with at least 3 spins left.") }
    private func info(_ title: String, _ message: String) { guard presentedViewController == nil else { return }; let a = UIAlertController(title:title,message:message,preferredStyle:.alert); a.addAction(UIAlertAction(title:"Got it",style:.default)); present(a,animated:true) }
}
