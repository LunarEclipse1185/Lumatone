//
//  LockButton.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/18.
//

import UIKit

class LockButton: UIView {
    
    var locked = true {
        didSet { symbol.image = UIImage(systemName: locked ? "lock.fill" : "lock.open") }
    }
    
    var keyboard: Keyboard?
    
    private let symbol: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "lock.fill"))
        view.contentMode = .scaleAspectFit
        view.preferredSymbolConfiguration = UIImage.SymbolConfiguration(paletteColors: [.gray, .gray])
        view.frame.origin = CGPointMake(10, 10)
        view.frame.size = CGSizeMake(30, 30)
        return view
    }()
    
    
    required init(coder: NSCoder) { fatalError() }
    
    init() {
        super.init(frame: CGRectMake(0, 0, 50, 50))
        
        backgroundColor = .white
        layer.cornerRadius = frame.width / 2
        layer.shadowColor = CGColor(gray: 0, alpha: 1)
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.5
        layer.shadowOffset = .zero
        layer.shadowPath = UIBezierPath(ovalIn: frame).cgPath
        
        addSubview(symbol)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        backgroundColor = .lightGray
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        backgroundColor = .white
        locked = !locked
        keyboard?.stopAllNotes()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
