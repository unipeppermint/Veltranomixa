import UIKit
import SnapKit

final class WheelView: UIView {
    private let rotor = UIView()
    private let ring = CAShapeLayer()
    private var sectors: [CAShapeLayer] = []
    private var labels: [UILabel] = []
    private var icons: [UIImageView] = []
    private let pointer = UIImageView(image: UIImage(systemName: "arrowtriangle.down.fill"))
    private let hub = UILabel()
    private var rotation: CGFloat = 0
    private var tiles: [Segment] = []
    init(run: RunState, skin: Int) {
        super.init(frame: .zero); tiles = run.wheel
        rotation = -CGFloat(run.lastResult?.index ?? 0) * .pi/4
        addSubview(rotor); rotor.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        rotor.layer.addSublayer(ring)
        rotor.layer.setValue(rotation, forKeyPath: "transform.rotation.z")
        rotor.layer.shadowColor = Theme.ink.cgColor; rotor.layer.shadowOpacity = 0.18; rotor.layer.shadowRadius = 8; rotor.layer.shadowOffset = CGSize(width: 0, height: 8)
        let palettes: [[UIColor]] = [[Theme.teal, UIColor(red: 1, green: 0.79, blue: 0.43, alpha: 1)], [Theme.orange, UIColor(red: 1, green: 0.79, blue: 0.63, alpha: 1)], [UIColor(red: 0.24, green: 0.32, blue: 0.55, alpha: 1), UIColor(red: 0.61, green: 0.66, blue: 0.85, alpha: 1)]]
        for (i,tile) in tiles.enumerated() {
            let shape = CAShapeLayer(); shape.fillColor = palettes[skin][i % 2].cgColor; shape.strokeColor = Theme.cream.withAlphaComponent(0.6).cgColor; shape.lineWidth = 1.5; rotor.layer.addSublayer(shape); sectors.append(shape)
            let bonus = tile.kind == .wood ? run.boost : (tile.kind == .coin ? run.coinBoost : (tile.kind == .shell ? run.shellBoost : 0))
            let value = [.wood,.coin,.shell].contains(tile.kind) ? "+\(tile.value + bonus)" : (tile.kind == .wind ? "×2" : "+1")
            let label = Theme.label("\(tile.kind.title)\n\(value)", size: 14, color: i % 2 == 0 ? .white : Theme.ink); label.textAlignment = .center; label.font = .systemFont(ofSize: 14, weight: .heavy); rotor.addSubview(label); labels.append(label)
            let icon = UIImageView(image: Art.item(tile.kind)); icon.contentMode = .scaleAspectFit; rotor.addSubview(icon); icons.append(icon)
        }
        hub.clipsToBounds = true; hub.text = "✦"; hub.font = .systemFont(ofSize: 44); hub.textColor = Theme.orange; hub.textAlignment = .center; hub.backgroundColor = Theme.cream; hub.layer.borderWidth = 5; hub.layer.borderColor = UIColor(red: 0.91, green: 0.67, blue: 0.35, alpha: 1).cgColor
        addSubview(hub); hub.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalToSuperview().multipliedBy(0.25) }
        pointer.tintColor = Theme.orange; pointer.contentMode = .scaleAspectFit; pointer.layer.shadowOpacity = 0.25; pointer.layer.shadowRadius = 3
        addSubview(pointer); pointer.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.equalToSuperview(); $0.width.equalTo(34); $0.height.equalTo(40) }
        isAccessibilityElement = true; accessibilityLabel = "八格转盘。" + tiles.map { "\($0.kind.title) \($0.value)" }.joined(separator: "，"); accessibilityHint = "每格概率 12.5%，使用下方按钮转动"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews(); hub.layer.cornerRadius = hub.bounds.width / 2
        let radius = rotor.bounds.width / 2 - 7; let center = CGPoint(x: rotor.bounds.midX, y: rotor.bounds.midY)
        ring.path = UIBezierPath(ovalIn: rotor.bounds.insetBy(dx: 2, dy: 2)).cgPath; ring.fillColor = Theme.cream.cgColor; ring.strokeColor = UIColor(red: 0.77, green: 0.48, blue: 0.22, alpha: 1).cgColor; ring.lineWidth = 8
        for i in 0..<8 {
            let angle = -CGFloat.pi/2 + CGFloat(i)*CGFloat.pi/4
            let p = UIBezierPath(); p.move(to: center); p.addArc(withCenter: center, radius: radius, startAngle: angle - .pi/8, endAngle: angle + .pi/8, clockwise: true); p.close(); sectors[i].path = p.cgPath
            labels[i].frame = CGRect(x: center.x + cos(angle)*radius*0.69 - 29, y: center.y + sin(angle)*radius*0.69 + 1, width: 58, height: 35)
            labels[i].font = .systemFont(ofSize: max(10, min(13, bounds.width/28)), weight: .bold)
            icons[i].frame = CGRect(x: center.x + cos(angle)*radius*0.69 - 24, y: center.y + sin(angle)*radius*0.69 - 36, width: 48, height: 42)
        }
    }
    func spin(to index: Int, duration: Double, completion: @escaping () -> Void) {
        let target = -CGFloat(index) * .pi/4
        let old = rotation; rotation = target + ceil((rotation-target) / (.pi*2)) * .pi*2 + .pi*8
        CATransaction.begin(); CATransaction.setCompletionBlock(completion)
        rotor.layer.setValue(rotation, forKeyPath: "transform.rotation.z")
        let a = CABasicAnimation(keyPath: "transform.rotation.z"); a.fromValue = old; a.toValue = rotation; a.duration = duration; a.timingFunction = CAMediaTimingFunction(controlPoints: 0.12, 0.7, 0.12, 1)
        rotor.layer.add(a, forKey: "spin"); CATransaction.commit()
        if duration > 0.2 {
            let tick = CAKeyframeAnimation(keyPath: "transform.rotation.z"); tick.values = [0, -0.2, 0]; tick.duration = 0.12; tick.repeatCount = Float(duration / 0.12); pointer.layer.add(tick, forKey: "tick")
        }
    }
}
