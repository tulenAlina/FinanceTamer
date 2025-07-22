#if canImport(UIKit)
import UIKit

public final class PieChartView: UIView {
    // MARK: - Public Properties
    public var entities: [Entity] = [] {
        didSet {
            guard oldValue != entities else { return }
            setNeedsDisplay()
        }
    }
    
    // MARK: - Private Properties
    private let segmentColors: [UIColor] = [
        UIColor(hex: "#2AE881"), UIColor(hex: "#FCE300"),
        UIColor(hex: "#FF9500"), UIColor(hex: "#FF2D55"),
        UIColor(hex: "#AF52DE"), UIColor(hex: "#F2F2F2")
    ]
    
    private let segmentLineWidth: CGFloat = 8
    private let legendFont = UIFont.systemFont(ofSize: 7, weight: .regular)
    private let legendDotSize: CGFloat = 5.65
    private let legendSpacing: CGFloat = 2.29
    private let legendRowSpacing: CGFloat = 3.23
    
    // MARK: - Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
    }
    
    // MARK: - Drawing
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard !entities.isEmpty else { return }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        
        drawChart(in: rect, context: context)
        drawLegend(in: rect)
        
        context.restoreGState()
    }
    
    private func drawChart(in rect: CGRect, context: CGContext) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) * 0.43
        let totalValue = entities.map { $0.value.doubleValue }.reduce(0, +)
        
        guard totalValue > 0 else { return }
        
        var startAngle: CGFloat = -.pi / 2
        for (index, entity) in entities.prefix(6).enumerated() {
            let value = CGFloat(entity.value.doubleValue / totalValue)
            let endAngle = startAngle + value * 2 * .pi
            
            let path = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )
            path.lineWidth = segmentLineWidth
            segmentColors[index].setStroke()
            path.stroke()
            
            startAngle = endAngle
        }
    }
    
    private func drawLegend(in rect: CGRect) {
        guard !entities.isEmpty else { return }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) * 0.43
        
        let legendRows: [(color: UIColor, text: String)] = entities.prefix(6).enumerated().map { index, entity in
            let percent = (entity.value.doubleValue / entities.map { $0.value.doubleValue }.reduce(0, +)) * 100
            let percentStr = String(format: "%.0f%%", percent)
            return (segmentColors[index], "\(percentStr) \(entity.label)")
        }
        
        let legendHeight = CGFloat(legendRows.count) * legendDotSize + CGFloat(legendRows.count - 1) * legendRowSpacing
        let legendWidth = legendRows.map { row in
            (row.text as NSString).size(withAttributes: [.font: legendFont]).width + legendDotSize + 3.23
        }.max() ?? 0
        
        let legendOrigin = CGPoint(x: center.x - legendWidth/2, y: center.y - legendHeight/2)
        
        for (i, row) in legendRows.enumerated() {
            let y = legendOrigin.y + CGFloat(i) * (legendDotSize + legendRowSpacing)
            let dotRect = CGRect(x: legendOrigin.x, y: y, width: legendDotSize, height: legendDotSize)
            
            let dotPath = UIBezierPath(ovalIn: dotRect)
            row.color.setFill()
            dotPath.fill()
            
            let textRect = CGRect(
                x: dotRect.maxX + 3.23,
                y: y + (legendDotSize-7)/2,
                width: legendWidth - dotRect.width - 3.23,
                height: 7
            )
            (row.text as NSString).draw(in: textRect, withAttributes: [
                .font: legendFont,
                .foregroundColor: UIColor.black
            ])
        }
    }
}

// MARK: - Helper Extensions
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8)*17, (int >> 4 & 0xF)*17, (int & 0xF)*17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: CGFloat(a)/255)
    }
}

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
}

#else
public final class PieChartView {
    public var entities: [Entity] = []
    public init() {
        fatalError("PieChartView is only available on iOS")
    }
}
#endif
