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
    private var latestMessage = "改造格子，规划下一转"
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
        do { (state, notice) = try repository.load() } catch { loadBlocked = true; notice = "无法打开存档：\(error.localizedDescription) 为保护进度，游戏暂时不能写入。" }
        NotificationCenter.default.addObserver(self, selector: #selector(background), name: UIApplication.didEnterBackgroundNotification, object: nil)
        render()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let notice { self.notice = nil; info("存档提示", notice) }
        else if !state.settings.tutorialSeen { tutorial() }
    }
    @objc private func background() { Feedback.shared.stop() }
    private func commit(_ change: (inout SaveEnvelope) throws -> Void) -> Bool {
        guard !loadBlocked else { info("存档未就绪", "请重新打开应用后再试，现有存档未被覆盖。"); return false }
        do { var next = state; try change(&next); try repository.write(next); state = next; return true }
        catch { info("操作未完成", "\(error.localizedDescription)\n进度未变更，可以重试。"); return false }
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
            for (title, symbol, destination) in [("小岛","house.fill", Page.island),("收藏","star.fill",Page.collection),("设置","gearshape.fill",Page.settings)] {
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
        add(Theme.label(eyebrow, size: 12, color: Theme.teal)); add(Theme.label(title, size: 30)); if let subtitle { add(Theme.label(subtitle, size: 15, color: Theme.ink.withAlphaComponent(0.65))) }
    }
    private func island() {
        heading("LUCKY ISLAND  /  用你的策略，建一座小岛", "幸运小岛", "改造八格转盘，读懂潮汐与林地，让每次选择留下风景。")
        let scene = IslandView(completed: state.completed); add(scene); scene.snp.makeConstraints { $0.height.equalTo(scene.snp.width).multipliedBy(0.93) }
        let levelID = min((0..<15).first(where: { !state.completed.contains($0) }) ?? 14, 14)
        let l = Content.levels[levelID]
        let content = Theme.stack([Theme.label("\(Content.regions[l.region])  ·  \(state.completed.count)/15", size: 13, color: Theme.teal), Theme.label("下一站：\(l.name)", size: 22), Theme.label(l.story, size: 15)])
        if let r = state.run, r.phase == .ready || r.phase == .upgrade || r.pending != nil {
            content.addArrangedSubview(Theme.button("继续 · \(Content.levels[r.level].name)", symbol: "play.fill", primary: true) { [weak self] in self?.go(.game) })
        } else {
            content.addArrangedSubview(Theme.button("开始挑战", symbol: "arrow.right", primary: true) { [weak self] in self?.detail(levelID) })
        }
        add(Theme.card(content)); add(Theme.button("探索三片区域 · 选择关卡", symbol: "map") { [weak self] in self?.go(.levels) })
    }
    private func levels() {
        heading("一座岛，十五段小小的故事", "小岛地图")
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
        let reward = id < 12 ? Content.buildings[id] : (id == 12 ? "珊瑚转盘" : (id == 13 ? "星夜转盘" : "庆典成就"))
        let a = UIAlertController(title: l.name, message: "\(l.story)\n\n目标：\(l.target)\n本关机制：\(l.rule.title)\n\(l.rule.detail)\n初始机会：\(l.turns) 次\n解锁：\(reward)\n额外挑战：获胜时剩余至少 3 次机会。\n\n\(state.run != nil ? "开始新挑战将替换当前对局，已有收藏保留。" : "每 3 次转动或遇见宝箱，可选择一次升级。")", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "开始挑战", style: .default) { [weak self] _ in
            guard let self else { return }; if self.commit({ try GameEngine.start(id, in: &$0) }) { self.latestMessage = "先试试免费换格，为目标资源腾出位置"; self.go(.game) }
        }); a.addAction(UIAlertAction(title: "再看看", style: .cancel)); present(a, animated: true)
    }
    private func game() {
        guard let r = state.run else { page = .island; island(); return }
        let header = UIStackView(); header.spacing = 10; header.distribution = .fill
        let back = Theme.button("小岛", symbol: "chevron.left") { [weak self] in self?.go(.island) }; header.addArrangedSubview(back)
        let title = Theme.label(Content.levels[r.level].name, size: 21); title.textAlignment = .center; header.addArrangedSubview(title)
        header.addArrangedSubview(Theme.button("规则", symbol: nil) { [weak self] in self?.rules() }); add(header)
        if r.pending == nil && r.phase == .upgrade { upgrades(r); return }
        if r.pending == nil && (r.phase == .won || r.phase == .lost) { result(r); return }
        #if DEBUG
        if ProcessInfo.processInfo.environment["ISLAND_UI_FIXED_WOOD"] == "1" { add(Theme.label("自动测试模式 · 固定格子结果", size: 12, color: .systemRed)) }
        #endif
        let l = Content.levels[r.level]
        let progress = Theme.stack([], spacing: 8)
        for (title, value, goal) in [("木材",r.wood,l.wood),("金币",r.coins,l.coins),("贝壳",r.shells,l.shells)] where goal > 0 {
            progress.addArrangedSubview(Theme.label("\(title)  \(value) / \(goal)", size: 20))
            let bar = UIProgressView(progressViewStyle: .default); bar.progressTintColor = Theme.teal; bar.trackTintColor = Theme.ink.withAlphaComponent(0.1); bar.progress = min(1, Float(value)/Float(goal)); bar.accessibilityLabel = title; bar.accessibilityValue = "\(value)，目标 \(goal)"; progress.addArrangedSubview(bar)
        }
        progress.addArrangedSubview(Theme.label(r.ruleStatus, size: 14, color: Theme.teal))
        add(Theme.card(progress))
        let stats = Theme.label("金币 \(r.coins)    ·    剩余 \(r.remaining) 次\(r.level >= 5 ? "    ·    贝壳 \(r.shells)" : "")", size: 17); stats.textAlignment = .center; add(stats)
        let w = WheelView(run: r, skin: state.settings.skin); wheel = w; add(w); w.snp.makeConstraints { $0.height.equalTo(w.snp.width) }
        let msg = Theme.label(r.pending != nil ? "已有转动结果已保存，点击查看" : latestMessage, size: 15, color: Theme.teal); msg.textAlignment = .center; msg.accessibilityIdentifier = "game.message"; add(msg)
        if r.doubleNext { let wind = Theme.label("顺风已就绪 · 下次木材或金币 ×2", size: 14); wind.textAlignment = .center; add(wind) }
        let spin = Theme.button(r.pending == nil ? "转动转盘" : "查看已保存的结果", symbol: "sparkles", primary: true) { [weak self] in self?.spin() }; spin.accessibilityIdentifier = "game.spin"; add(spin)
        let craft = Theme.button((r.freeRefits ?? 0) > 0 ? "免费换一格 · 规划转盘" : "转盘工坊 · 调整资源布局", symbol: "hammer.fill") { [weak self] in self?.craft() }; craft.accessibilityIdentifier = "game.workshop"; craft.isEnabled = r.pending == nil; add(craft)
        if (r.freeRefits ?? 0) > 0 { add(Theme.label("试着把金币格换成木材格：木材命中率从 37.5% 变为 50%。首次换格免费，后续每次 6 金币。", size: 14, color: Theme.teal)) }
        let caption = Theme.label("8 格等概率 · 每格 12.5%\n工具 +\(r.boost)  ·  每 3 转升级一次  ·  仅本局生效", size: 12, color: Theme.ink.withAlphaComponent(0.6)); caption.textAlignment = .center; add(caption)
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
                self.latestMessage = record.message; self.render(); self.rewardFlight(record)
                UIAccessibility.post(notification: .announcement, argument: record.message)
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
        heading("成长、续航，还是即时补给？", "选择一项升级", "\(latestMessage)\n\(r.ruleStatus)\n升级仅在当前挑战内生效。")
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
            b.accessibilityLabel = "\(upgrade.title)，\(upgrade.detail)"
            b.accessibilityTraits = upgrade == selected ? [.button, .selected] : .button; add(b)
        }
        add(Theme.button("确认升级", primary: true) { [weak self] in
            guard let self, let choice = self.selectedUpgrade else { return }
            if self.commit({ try GameEngine.choose(choice, in: &$0) }) { self.selectedUpgrade = nil; self.latestMessage = "\(choice.title)已生效"; Feedback.shared.play(self.state.settings); self.render() }
        })
        add(Theme.label("剩余 \(r.remaining) 次 · 木材 \(r.wood) · 金币 \(r.coins)\n最后一次转动仍可选择增加机会的升级。", size: 14))
    }
    private func result(_ r: RunState) {
        let won = r.phase == .won
        heading(won ? "又一份幸运，成为小岛的风景" : "海风会带来下一次机会", won ? "\(Content.levels[r.level].name) · 完成" : "差一点就完成了", won ? (r.level < 12 ? "建设成果已自动加入小岛与收藏。" : (r.level < 14 ? "新转盘外观已加入收藏，可前往衣橱使用。" : "小岛庆典成就已解锁，谢谢你为小岛带来这么多风景。")) : "\(Content.levels[r.level].rule.detail) 下次试试不同的格子布局。")
        if r.level < 12 {
            let art = UIImageView(image: Art.building(r.level)); art.contentMode = .scaleAspectFit; add(art); art.snp.makeConstraints { $0.height.equalTo(220) }
        } else {
            let preview = WheelView(run: r, skin: r.level == 12 ? 1 : 2); add(preview); preview.snp.makeConstraints { $0.height.equalTo(preview.snp.width) }
        }
        add(Theme.card(Theme.stack([Theme.label("木材 \(r.wood)   金币 \(r.coins)   贝壳 \(r.shells)",size:18), Theme.label("转动 \(r.spins) 次 · 改造 \(r.crafts) 次",size:15),Theme.label(won && r.remaining >= 3 ? "★ 额外挑战完成：留有余裕" : "额外挑战：获胜时保留至少 3 次机会",size:14)])))
        if won && r.level < 14 { add(Theme.button("下一站", symbol: "arrow.right", primary: true) { [weak self] in self?.detail(r.level + 1) }) }
        add(Theme.button("再挑战一次", symbol: "arrow.clockwise", primary: !won) { [weak self] in self?.detail(r.level) })
        add(Theme.button("回到小岛", symbol: "house.fill") { [weak self] in self?.go(.island) })
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
        add(Theme.button("返回对局", symbol: "chevron.left") { [weak self] in self?.go(.game) })
        heading("每个格子，都是一次选择", "转盘工坊", "金币 \(r.coins) · \(r.ruleStatus)\n\(r.mechanicsVersion == 1 ? Content.levels[r.level].rule.detail : "当前对局沿用经典规则。")")
        if r.canReplace {
            add(Theme.label("1 · 选择原格子", size: 20))
            add(Theme.label("从转盘顶部起顺时针编号 1–8。替换宝箱或顺风，也会失去对应效果。", size: 13))
            var slotRow = UIStackView()
            for (index, tile) in r.wheel.enumerated() {
                if index % 2 == 0 { slotRow = UIStackView(); slotRow.spacing = 8; slotRow.distribution = .fillEqually; add(slotRow) }
                let b = Theme.button("\(index + 1)  \(tile.kind.title) · 基础 \(tile.value)", symbol: selectedSlot == index ? "checkmark.circle.fill" : "circle") { [weak self] in
                    self?.selectedSlot = index; self?.refreshWorkshop()
                }
                b.accessibilityIdentifier = "workshop.slot.\(index)"; slotRow.addArrangedSubview(b)
            }
            add(Theme.label("2 · 选择新资源", size: 20))
            for kind in r.level >= 5 ? [Tile.wood, .coin, .shell] : [.wood, .coin] {
                let b = Theme.button("\(kind.title) · 基础 +2", symbol: selectedKind == kind ? "checkmark.circle.fill" : "circle") { [weak self] in
                    self?.selectedKind = kind; self?.refreshWorkshop()
                }
                b.accessibilityIdentifier = "workshop.kind.\(kind.rawValue)"; add(b)
            }
            var preview = r
            preview.wheel[selectedSlot] = Segment(kind: selectedKind, value: 2)
            var lines = ["第 \(selectedSlot + 1) 格：\(r.wheel[selectedSlot].kind.title) → \(selectedKind.title)"]
            for kind in r.level >= 5 ? [Tile.wood, .coin, .shell] : [.wood, .coin] {
                lines.append("\(kind.title)命中率：\(r.probability(kind))% → \(preview.probability(kind))%")
            }
            lines.append("下一转若命中此格：+\(preview.yield(at: selectedSlot, spinNumber: r.spins + 1)) \(selectedKind.title)（含当前加成）")
            if r.rule == .grove { lines.append("相邻木材也会获得连携加成；1 号与 8 号格相邻。") }
            let level = Content.levels[r.level]
            for (kind, held, target) in [(Tile.wood, r.wood, level.wood), (.coin, r.coins, level.coins), (.shell, r.shells, level.shells)] where held < target && preview.probability(kind) == 0 {
                lines.append("注意：\(kind.title)目标尚未完成，换格后转盘不再产出该资源。")
            }
            lines.append("花费 \(r.replacementCost) 金币 · 剩余 \(max(0, r.coins - r.replacementCost)) 金币\(level.coins > 0 ? " · 通关需保留 \(level.coins) 金币" : "")")
            let previewLabel = Theme.label(lines.joined(separator: "\n"), size: 15)
            previewLabel.accessibilityIdentifier = "workshop.preview"; add(Theme.card(previewLabel))
            let same = r.wheel[selectedSlot] == preview.wheel[selectedSlot]
            let apply = Theme.button(same ? "此格已是相同配置" : (r.replacementCost == 0 ? "确认免费换格" : "确认换格 · 6 金币"), symbol: "hammer.fill", primary: true) { [weak self] in
                guard let self else { return }; self.buyCraft(index: self.selectedSlot, kind: self.selectedKind)
            }
            apply.accessibilityIdentifier = "workshop.apply"
            apply.isEnabled = !same && r.coins >= r.replacementCost; add(apply)
        }
        add(Theme.label("另一种选择 · 保持布局，提高产出", size: 18))
        let reinforce = Theme.button("4 金币 · 所有木材格 +1", symbol: "wrench.fill") { [weak self] in self?.buyCraft() }
        reinforce.isEnabled = r.coins >= 4; add(reinforce)
        add(Theme.label("强化可叠加，不改变命中率。全部改造仅本局有效。", size: 13))
    }
    private func buyCraft(index: Int? = nil, kind: Tile = .wood) {
        guard let before = state.run else { return }
        if commit({ try GameEngine.craft(&$0, replacing: index, with: kind) }) {
            latestMessage = index == nil ? "木材格产出 +1，布局保持不变" : "\(kind.title)命中率 \(before.probability(kind))% → \(state.run!.probability(kind))%"
            Feedback.shared.play(state.settings); go(.game)
        }
    }
    private func collection() {
        heading("每一份幸运，都留下了痕迹", "小岛收藏", "建筑 \(state.completed.filter { $0 < 12 }.count)/12 · 成就 \(state.achievements.filter { $0 }.count)/10")
        for i in 0..<12 {
            let unlocked = state.completed.contains(i)
            let row = UIStackView(); row.spacing = 14; row.alignment = .center
            let image = UIImageView(image: Art.building(i)); image.contentMode = .scaleAspectFit; image.alpha = unlocked ? 1 : 0.28; row.addArrangedSubview(image); image.snp.makeConstraints { $0.width.height.equalTo(82) }
            row.addArrangedSubview(Theme.stack([Theme.label(Content.buildings[i],size:19), Theme.label(unlocked ? "已建成 · 小岛上见" : "完成第 \(i+1) 关解锁", size:13,color:Theme.teal)])); add(Theme.card(row))
        }
        add(Theme.label("旅途成就",size:24))
        for (i, achieved) in state.achievements.enumerated() { add(Theme.card(Theme.stack([Theme.label("\(achieved ? "★" : "☆")  \(SaveEnvelope.achievementNames[i])",size:18),Theme.label(SaveEnvelope.achievementDetails[i],size:14)]))) }
        add(Theme.label("转盘衣橱",size:24))
        for (i, name) in ["海风","珊瑚","星夜"].enumerated() {
            let unlocked = i == 0 || state.completed.contains(i == 1 ? 12 : 13)
            let b = Theme.button("\(name)\(state.settings.skin == i ? " · 使用中" : "")\(unlocked ? "" : " · 第 \(i == 1 ? 13 : 14) 关解锁")",symbol:unlocked ? "circle.lefthalf.filled" : "lock.fill") { [weak self] in guard let self else { return }; if self.commit({ $0.settings.skin = i }) { self.render() } }; b.isEnabled = unlocked; add(b)
        }
    }
    private func settings() {
        heading("按自己的节奏，享受小岛时光", "设置")
        for (name,key) in [("游戏音效",0),("触感反馈",1),("快速转动",2)] {
            let row = UIStackView(); row.alignment = .center; row.spacing = 16
            row.addArrangedSubview(Theme.label(name)); let toggle = UISwitch(); toggle.onTintColor = Theme.teal; toggle.isOn = key == 0 ? state.settings.sound : (key == 1 ? state.settings.haptics : state.settings.fast); toggle.accessibilityLabel = name
            toggle.addAction(UIAction { [weak self, weak toggle] _ in guard let self, let toggle else { return }; let on = toggle.isOn; if !self.commit({ if key == 0 { $0.settings.sound = on } else if key == 1 { $0.settings.haptics = on } else { $0.settings.fast = on } }) { toggle.isOn = !on }; if key == 0 && !on { Feedback.shared.stop() } }, for: .valueChanged); row.addArrangedSubview(toggle); add(Theme.card(row))
        }
        add(Theme.button("重新查看教学",symbol:"questionmark.circle") { [weak self] in self?.tutorial() })
        add(Theme.button("玩法与概率",symbol:"info.circle") { [weak self] in self?.rules() })
        add(Theme.button("隐私与本地存档",symbol:"lock.shield") { [weak self] in self?.info("你的岛，只在你的设备上", "本应用无需账号，不接入广告、分析或服务器，不收集或传输个人信息。游戏进度和设置仅保存在设备上，无云同步。删除应用可能导致进度丢失。\n\n每次操作自动保存，转动中离开也不会重新抽取。系统减弱动态效果开启时自动缩短转盘动画。") })
        add(Theme.button("关于与支持",symbol:"lifepreserver") { [weak self] in self?.info("幸运小岛 · 1.0", "单人离线的小岛建设游戏。\n若遇到问题，请先重新打开应用；请勿删除应用，以免丢失存档。发行前将补充正式支持网址。\n\n插画：OpenAI ImageGen 生成\n音效：项目原创合成\n布局：SnapKit 5.7.1（MIT）\n完整开源许可随应用附带。") })
        add(Theme.button("开源许可",symbol:"doc.text") { [weak self] in let url = Bundle.main.url(forResource:"SnapKit-LICENSE",withExtension:"txt"); self?.info("SnapKit · MIT License", url.flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "请参见项目 Pods/SnapKit/LICENSE。") })
        add(Theme.button("清空所有进度",symbol:"trash") { [weak self] in self?.reset() })
        add(Theme.label("本地自动保存 · 无广告 · 无内购\n当前为开发版本，正式发行资料另行准备。",size:13,color:Theme.ink.withAlphaComponent(0.6)))
    }
    private func reset() {
        let a = UIAlertController(title:"清空这座小岛？",message:"当前对局、所有建筑与成就将被删除，无法撤销。",preferredStyle:.alert)
        a.addAction(UIAlertAction(title:"清空进度",style:.destructive) { [weak self] _ in guard let self, !self.loadBlocked else { return }; do { try self.repository.reset(); self.state = SaveEnvelope(); self.go(.island) } catch { self.info("未能清空", error.localizedDescription) } }); a.addAction(UIAlertAction(title:"保留小岛",style:.cancel)); present(a,animated:true)
    }
    private func tutorial() {
        let a = UIAlertController(title:"欢迎来到幸运小岛",message:"① 选择建设目标，先到工坊免费换一格。增加目标资源格，就能提高命中率。\n\n② 每 3 次转动或遇见宝箱，选择一次升级。工具可以叠加，顺风只保留一次。\n\n③ 林地关把木材格连起来；潮汐关留意每第 3 转的涨潮；集市关交替奖励木材与金币。在机会耗尽前达成目标。成功后建筑永久保留，失败可随时重试。\n\n所有格子等概率，没有体力等待。进度会自动保存。",preferredStyle:.alert)
        a.addAction(UIAlertAction(title:"让好运靠岸",style:.default) { [weak self] _ in _ = self?.commit { $0.settings.tutorialSeen = true } }); present(a,animated:true)
    }
    private func rules() { info("公开规则 · 每格 12.5%", "8 个等大格子均匀抽取，没有隐藏概率调整。\n\n木材、金币：基础值加工具加成，再乘顺风倍率。顺风仅对下次木材或金币生效，不叠加、不被其他格子消耗。\n\n宝箱：三选一升级；天气：获得顺风。贝壳：基础值加贝壳工艺。补给：机会 +1、木材 +1。\n\n每转动 3 次可升级，与宝箱同时触发只选一次。最后一转先结算目标，再处理升级，最后检查次数。\n\n新对局首次换格免费，之后 6 金币替换一格，新格基础产出 2；4 金币强化所有木材格。工坊预览命中率和下一转产出。\n\n林地：每个相邻木材格使命中木材 +1；潮汐：每第 3 转贝壳 +3，其余转木材 +1；集市：奇数转木材 +2、偶数转金币 +2。关卡加成在顺风翻倍之前计算，盘面数值为基础值加工具；关卡加成与顺风计入实际结算，工坊可预览。旧版进行中对局保持经典规则。局内改造不带入下一局。\n\n额外挑战：获胜时保留至少 3 次机会。") }
    private func info(_ title: String, _ message: String) { guard presentedViewController == nil else { return }; let a = UIAlertController(title:title,message:message,preferredStyle:.alert); a.addAction(UIAlertAction(title:"知道了",style:.default)); present(a,animated:true) }
}
