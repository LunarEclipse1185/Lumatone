//
//  Handle.swift
//  Lumatone
//
//  Created by SH BU on 2024/8/16.
//

import UIKit

class Handle : UIView {
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        // TODO: design handle UI
        
        // userdefault data read by ViewController
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        NotificationCenter.default.post(name: .panelHandleSwitched, object: self)
        UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: "controlPanelFolded_Bool"), forKey: "controlPanelFolded_Bool")
    }
    
    lazy var cornerRadius = 0.4 * frame.height
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if point.x < cornerRadius || point.x > frame.width - cornerRadius {
            return nil
        }
        return super.hitTest(point, with: event)
    }
    
    let image = UIImage(systemName: "line.3.horizontal")!
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.beginPath()
        ctx.move(to: .zero)
        ctx.addArc(center: CGPointMake(0, cornerRadius),
                   radius: cornerRadius,
                   startAngle: 0.5 * CGFloat.pi,
                   endAngle: 0,
                   clockwise: false)
        ctx.addLine(to: CGPointMake(cornerRadius, rect.height - cornerRadius))
        ctx.addArc(center: CGPointMake(2 * cornerRadius, rect.height - cornerRadius),
                   radius: cornerRadius,
                   startAngle: CGFloat.pi,
                   endAngle: 0.5 * CGFloat.pi,
                   clockwise: true)
        ctx.addLine(to: CGPointMake(rect.width - 2 * cornerRadius, rect.height))
        ctx.addArc(center: CGPointMake(rect.width - 2 * cornerRadius, rect.height - cornerRadius),
                   radius: cornerRadius,
                   startAngle: 0.5 * CGFloat.pi,
                   endAngle: 0 * CGFloat.pi,
                   clockwise: true)
        ctx.addLine(to: CGPointMake(rect.width - cornerRadius, cornerRadius))
        ctx.addArc(center: CGPointMake(rect.width, cornerRadius),
                   radius: cornerRadius,
                   startAngle: CGFloat.pi,
                   endAngle: 0.5 * CGFloat.pi,
                   clockwise: false)
        ctx.addLine(to: CGPointMake(rect.width, 0))
        ctx.closePath()
        ctx.setFillColor( #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1) )
        ctx.fillPath()
        
        image.draw(in: CGRectMake(rect.minX + rect.width / 2 - image.size.width / 2,
                                       rect.minY + rect.height / 2 - image.size.height / 2,
                                       image.size.width, image.size.height))
    }
}
