import UIKit
import SnapKit
import AVFoundation

enum Theme {
    static let ink = UIColor(red: 0.04, green: 0.22, blue: 0.29, alpha: 1)
    static let teal = UIColor(red: 0.02, green: 0.57, blue: 0.61, alpha: 1)
    static let cream = UIColor(red: 1, green: 0.97, blue: 0.91, alpha: 1)
    static let orange = UIColor(red: 1, green: 0.36, blue: 0.15, alpha: 1)
    static func font(_ size: CGFloat, _ weight: UIFont.Weight = .semibold) -> UIFont { UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: size, weight: weight), maximumPointSize: size * 1.65) }
    static func label(_ text: String, size: CGFloat = 17, color: UIColor = ink) -> UILabel {
        let label = UILabel(); label.text = text; label.font = font(size); label.textColor = color; label.numberOfLines = 0; label.adjustsFontForContentSizeCategory = true; return label
    }
    static func button(_ title: String, symbol: String? = nil, primary: Bool = false, action: @escaping () -> Void) -> UIButton {
        var config = UIButton.Configuration.filled(); config.title = title
        config.baseBackgroundColor = primary ? orange : cream; config.baseForegroundColor = primary ? .white : ink
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        config.cornerStyle = .large; config.contentInsets = .init(top: 16, leading: 18, bottom: 16, trailing: 18)
        if let symbol { config.image = UIImage(systemName: symbol); config.imagePadding = 9 }
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { var a = $0; a.font = font(17, .bold); return a }
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() }); button.titleLabel?.numberOfLines = 0
        button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(52) }; return button
    }
    static func card(_ content: UIView) -> UIView {
        let v = UIView(); v.backgroundColor = cream; v.layer.cornerRadius = 24; v.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor; v.layer.borderWidth = 1
        v.layer.shadowColor = ink.cgColor; v.layer.shadowOpacity = 0.08; v.layer.shadowRadius = 12; v.layer.shadowOffset = CGSize(width: 0, height: 5)
        v.addSubview(content); content.snp.makeConstraints { $0.edges.equalToSuperview().inset(18) }; return v
    }
    static func stack(_ views: [UIView], spacing: CGFloat = 12) -> UIStackView { let s = UIStackView(arrangedSubviews: views); s.axis = .vertical; s.spacing = spacing; return s }
}
enum Art {
    static let atlas = UIImage(named: "buildings")
    static let items = UIImage(named: "items")
    static var itemCache: [Tile: UIImage] = [:]
    static func item(_ kind: Tile) -> UIImage? {
        if let image = itemCache[kind] { return image }
        guard let cg = items?.cgImage, let index = Tile.allCases.firstIndex(of: kind) else { return nil }
        let w = cg.width / 3, h = cg.height / 2
        guard let crop = cg.cropping(to: CGRect(x: index % 3 * w, y: index / 3 * h, width: w, height: h)) else { return nil }
        let image = UIImage(cgImage: crop); itemCache[kind] = image; return image
    }
    static var cached: [Int: UIImage] = [:]
    static func building(_ index: Int) -> UIImage? {
        if let image = cached[index] { return image }
        guard let cg = atlas?.cgImage else { return nil }
        let width = cg.width / 4, height = cg.height / 3
        guard let crop = cg.cropping(to: CGRect(x: index % 4 * width, y: index / 4 * height, width: width, height: height)) else { return nil }
        let image = UIImage(cgImage: crop); cached[index] = image; return image
    }
}
final class Feedback {
    static let shared = Feedback()
    private var player: AVAudioPlayer?
    func play(_ settings: Preferences, success: Bool = false) {
        if settings.haptics { if success { UINotificationFeedbackGenerator().notificationOccurred(.success) } else { UIImpactFeedbackGenerator(style: .soft).impactOccurred() } }
        guard settings.sound, let url = Bundle.main.url(forResource: success ? "success" : "spin", withExtension: "wav") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        player = try? AVAudioPlayer(contentsOf: url); player?.volume = 0.45; player?.play()
    }
    func stop() { player?.stop() }
}
final class IslandView: UIView {
    private let sea = UIImageView(image: UIImage(named: "island"))
    private var buildings: [UIImageView] = []
    init(completed: Set<Int>) {
        super.init(frame: .zero); clipsToBounds = true; layer.cornerRadius = 28
        sea.contentMode = .scaleAspectFill; addSubview(sea); sea.snp.makeConstraints { $0.edges.equalToSuperview() }
        for index in 0..<12 where completed.contains(index) {
            let v = UIImageView(image: Art.building(index)); v.contentMode = .scaleAspectFit; v.tag = index; addSubview(v); buildings.append(v)
        }
        isAccessibilityElement = true; accessibilityLabel = "我的小岛，已建成 \(completed.filter { $0 < 12 }.count) 处景观"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        let points: [(CGFloat,CGFloat)] = [(0.64,0.22),(0.32,0.36),(0.22,0.52),(0.47,0.52),(0.55,0.65),(0.83,0.72),(0.44,0.23),(0.60,0.44),(0.19,0.35),(0.74,0.44),(0.69,0.61),(0.36,0.67)]
        for b in buildings { let p = points[b.tag]; let size = bounds.width * (b.tag == 0 ? 0.27 : 0.22); b.frame = CGRect(x: bounds.width*p.0-size/2, y: bounds.height*p.1-size/2, width: size, height: size) }
    }
}
