import SwiftUI

struct SpoilerText: View {
    let balance: String
    let currencySymbol: String
    @Binding var isHidden: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            if isHidden {
                SpoilerEffectView()
                    .frame(height: 24)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Text(balance)
            }
            Text(currencySymbol)
        }
    }
}

struct SpoilerEffectView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = SpoilerUIView()
        view.startAnimation()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let spoilerView = uiView as? SpoilerUIView else { return }
        spoilerView.isAnimating = true
        spoilerView.startAnimation()
    }
}

class SpoilerUIView: UIView {
    var isAnimating = false
    
    override class var layerClass: AnyClass {
        return CAEmitterLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil && isAnimating {
            startAnimation()
        } else {
            stopAnimation()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let emitterLayer = self.layer as? CAEmitterLayer {
            emitterLayer.emitterSize = bounds.size
            emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        }
    }
    
    func startAnimation() {
        guard let emitterLayer = self.layer as? CAEmitterLayer else { return }
        
        emitterLayer.emitterShape = .rectangle
        emitterLayer.emitterMode = .surface
        emitterLayer.emitterSize = bounds.size
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        
        let cell = CAEmitterCell()
        cell.contents = UIImage(systemName: "circle.fill")?.withTintColor(.label).cgImage
        cell.scale = 0.05
        cell.scaleRange = 0.03
        cell.emissionRange = .pi * 2.0
        cell.lifetime = 1.0
        cell.birthRate = Float(bounds.width * bounds.height / 50)
        cell.velocity = 5
        cell.velocityRange = 10
        cell.alphaSpeed = -0.5
        cell.yAcceleration = 20
        cell.spin = .pi
        cell.spinRange = .pi * 2.0
        cell.color = UIColor.label.cgColor
        
        emitterLayer.emitterCells = [cell]
        isAnimating = true
    }
    
    func stopAnimation() {
        guard let emitterLayer = self.layer as? CAEmitterLayer else { return }
        emitterLayer.emitterCells = nil
        isAnimating = false
    }
}
