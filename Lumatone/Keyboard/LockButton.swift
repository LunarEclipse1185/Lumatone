//
//  LockButton.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/18.
//

import UIKit

class LockButton: UIView {
    
    var locked = true;
    
    var keyboard: Keyboard?
    
    lazy private var symbol: UIImageView = {
        let img = UIImage(systemName: "lock.fill")
        
        let imgV = UIImageView(image: img)
        imgV.contentMode = .scaleAspectFit
        
        var config = UIImage.SymbolConfiguration(paletteColors: [.gray, .gray])
        //config = config.applying(UIImage.SymbolConfiguration(scale: .large))
        imgV.preferredSymbolConfiguration = config
        
        imgV.frame.origin = CGPointMake(10, 10)
        imgV.frame.size = CGSizeMake(30, 30)
        
        
        return imgV
    }()
    
    
    required init(coder: NSCoder) { fatalError() }
    
    init() {
        super.init(frame: CGRectMake(0, 0, 50, 50))
        self.backgroundColor = .white
        self.layer.cornerRadius = frame.width / 2
        self.layer.shadowColor = CGColor(gray: 0, alpha: 1)
        self.layer.shadowRadius = 10
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = .zero
        //self.layer.shouldRasterize = true
        //self.layer.rasterizationScale = UIScreen.main.scale
        
        addSubview(symbol)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = .lightGray
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = .white
        locked = !locked
        keyboard?.stopAllNotes()
        
        symbol.image = UIImage(systemName: locked ? "lock.fill" : "lock.open")
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
