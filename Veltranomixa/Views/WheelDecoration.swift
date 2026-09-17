import UIKit

/// A small, cached illustration using the same palette and resource artwork as the game.
/// It has no gameplay state and is never announced as an interactive wheel.
enum WheelDecoration {
    static let image: UIImage = {
        let format = UIGraphicsImageRendererFormat(); format.scale = 2
        return UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120), format: format).image { renderer in
            let context = renderer.cgContext
            let center = CGPoint(x: 60, y: 63)
            context.saveGState()
            context.setShadow(offset: CGSize(width: 0, height: 3), blur: 5, color: Theme.ink.withAlphaComponent(0.16).cgColor)
            UIColor(red: 0.76, green: 0.46, blue: 0.22, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 10, y: 13, width: 100, height: 100)).fill()
            context.restoreGState()
            let gold = UIColor(red: 1, green: 0.78, blue: 0.43, alpha: 1)
            for index in 0..<8 {
                let angle = -CGFloat.pi / 2 + CGFloat(index) * .pi / 4
                let sector = UIBezierPath(); sector.move(to: center)
                sector.addArc(withCenter: center, radius: 45, startAngle: angle - .pi / 8, endAngle: angle + .pi / 8, clockwise: true); sector.close()
                (index % 2 == 0 ? Theme.teal : gold).setFill(); sector.fill()
                Theme.cream.withAlphaComponent(0.7).setStroke(); sector.lineWidth = 0.8; sector.stroke()
                let kind: Tile = index % 2 == 0 ? .wood : .coin
                let location = CGPoint(x: center.x + cos(angle) * 32, y: center.y + sin(angle) * 32)
                Art.item(kind)?.draw(in: CGRect(x: location.x - 9, y: location.y - 9, width: 18, height: 18))
            }
            Theme.cream.setFill(); let hub = UIBezierPath(ovalIn: CGRect(x: 44, y: 47, width: 32, height: 32)); hub.fill()
            gold.setStroke(); hub.lineWidth = 3; hub.stroke()
            let sun = UIImage(systemName: "sun.max.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18))?.withTintColor(Theme.orange, renderingMode: .alwaysOriginal)
            sun?.draw(in: CGRect(x: 50, y: 53, width: 20, height: 20))
            let pointer = UIBezierPath(); pointer.move(to: CGPoint(x: 52, y: 9)); pointer.addLine(to: CGPoint(x: 68, y: 9)); pointer.addLine(to: CGPoint(x: 60, y: 29)); pointer.close()
            Theme.orange.setFill(); pointer.fill()
        }
    }()
}
