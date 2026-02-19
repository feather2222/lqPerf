import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
final class LQPerfChartView: UIView {
    var values: [Double] = [] {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    private let maxLabel = UILabel()
    private let minLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        if #available(iOS 13.0, *) {
            backgroundColor = UIColor.systemGray6
            maxLabel.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .medium)
            minLabel.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .medium)
            maxLabel.textColor = .secondaryLabel
            minLabel.textColor = .secondaryLabel
        } else {
            backgroundColor = UIColor(white: 0.95, alpha: 1.0)
            maxLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            minLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            maxLabel.textColor = .darkGray
            minLabel.textColor = .darkGray
        }
        layer.cornerRadius = 8
        layer.masksToBounds = true
        addSubview(maxLabel)
        addSubview(minLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        maxLabel.frame = CGRect(x: 8, y: 4, width: bounds.width - 16, height: 14)
        minLabel.frame = CGRect(x: 8, y: bounds.height - 18, width: bounds.width - 16, height: 14)
        updateLabels()
    }

    private func updateLabels() {
        guard let max = values.max(), let min = values.min() else {
            maxLabel.text = "Max: --"
            minLabel.text = "Min: --"
            return
        }
        maxLabel.text = String(format: "Max: %.2f", max)
        minLabel.text = String(format: "Min: %.2f", min)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard values.count >= 2 else { return }

        let path = UIBezierPath()
        let maxV = values.max() ?? 1
        let minV = values.min() ?? 0
        let range = max(maxV - minV, 0.0001)

        let inset: CGFloat = 24
        let width = rect.width - inset * 2
        let height = rect.height - inset * 2

        for (index, value) in values.enumerated() {
            let x = inset + (CGFloat(index) / CGFloat(values.count - 1)) * width
            let yRatio = (value - minV) / range
            let y = rect.height - inset - CGFloat(yRatio) * height
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        UIColor.systemBlue.setStroke()
        path.lineWidth = 2
        path.stroke()
    }
}
#endif
