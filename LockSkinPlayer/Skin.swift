import UIKit

// These are original retro-inspired themes, not copies of Winamp artwork.
enum Skin: String, CaseIterable, Identifiable, Codable {
    case classic = "Classic Green"
    case amber = "Amber LCD"
    case midnight = "Midnight Blue"
    case ruby = "Ruby Deck"

    var id: String { rawValue }

    var background: UIColor {
        switch self {
        case .classic: return UIColor(red: 0.13, green: 0.16, blue: 0.17, alpha: 1)
        case .amber: return UIColor(red: 0.15, green: 0.11, blue: 0.08, alpha: 1)
        case .midnight: return UIColor(red: 0.07, green: 0.12, blue: 0.22, alpha: 1)
        case .ruby: return UIColor(red: 0.18, green: 0.07, blue: 0.13, alpha: 1)
        }
    }

    var accent: UIColor {
        switch self {
        case .classic: return UIColor(red: 0.51, green: 0.95, blue: 0.30, alpha: 1)
        case .amber: return UIColor(red: 1, green: 0.72, blue: 0.25, alpha: 1)
        case .midnight: return UIColor(red: 0.34, green: 0.82, blue: 1, alpha: 1)
        case .ruby: return UIColor(red: 1, green: 0.42, blue: 0.60, alpha: 1)
        }
    }
}

struct SkinArtwork {
    static func render(_ skin: Skin, title: String) -> UIImage {
        let size = CGSize(width: 600, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            skin.background.setFill()
            cg.fill(CGRect(origin: .zero, size: size))
            let border = CGRect(x: 18, y: 18, width: 564, height: 564)
            cg.setStrokeColor(skin.accent.cgColor)
            cg.setLineWidth(5)
            cg.stroke(border)
            let panel = CGRect(x: 38, y: 78, width: 524, height: 360)
            cg.setFillColor(UIColor.black.withAlphaComponent(0.45).cgColor)
            cg.fill(panel)
            cg.setStrokeColor(skin.accent.withAlphaComponent(0.55).cgColor)
            cg.setLineWidth(2)
            cg.stroke(panel)

            let labelStyle: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 25, weight: .bold),
                .foregroundColor: skin.accent
            ]
            ("LOCK SKIN PLAYER" as NSString).draw(at: CGPoint(x: 48, y: 34), withAttributes: labelStyle)
            let safeTitle = String(title.prefix(60))
            let trackStyle: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 30, weight: .semibold),
                .foregroundColor: skin.accent
            ]
            (safeTitle as NSString).draw(in: CGRect(x: 56, y: 104, width: 488, height: 86), withAttributes: trackStyle)

            // A static equalizer motif. System artwork is not an interactive widget.
            let bars: [CGFloat] = [0.30, 0.60, 0.44, 0.78, 0.51, 0.91, 0.57, 0.36, 0.70, 0.48, 0.84, 0.61, 0.43, 0.73, 0.33]
            for (index, height) in bars.enumerated() {
                let x = 60 + CGFloat(index) * 32
                let h = height * 166
                cg.setFillColor(skin.accent.withAlphaComponent(index.isMultiple(of: 3) ? 1 : 0.7).cgColor)
                cg.fill(CGRect(x: x, y: 384 - h, width: 19, height: h))
            }
            cg.setStrokeColor(skin.accent.cgColor)
            cg.setLineWidth(4)
            cg.move(to: CGPoint(x: 60, y: 408))
            cg.addLine(to: CGPoint(x: 540, y: 408))
            cg.strokePath()
            ("◀◀    ▶ / ❚❚    ▶▶" as NSString).draw(at: CGPoint(x: 104, y: 474), withAttributes: [
                .font: UIFont.systemFont(ofSize: 38, weight: .semibold),
                .foregroundColor: skin.accent
            ])
            (skin.rawValue.uppercased() as NSString).draw(at: CGPoint(x: 50, y: 543), withAttributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 18, weight: .medium),
                .foregroundColor: skin.accent
            ])
        }
    }
}
