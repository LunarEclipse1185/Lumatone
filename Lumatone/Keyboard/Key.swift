//
//  KeyView.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/16.
//

import UIKit
import AVFoundation


class Key: UIView {
    
//    static var idleImage = #imageLiteral(resourceName: "keyIdle.svg")
//    static var PressedImage = #imageLiteral(resourceName: "keyPressed.svg")
//    static var idleGlowImage = #imageLiteral(resourceName: "keyIdleGlow.svg")
//    static var pressedGlowImage = #imageLiteral(resourceName: "keyPressedGlow.svg")
    
    public static var keyImage = #imageLiteral(resourceName: "key.svg")
    public static var shadowImage = #imageLiteral(resourceName: "keyShadow.svg")
    public static var glowImage = #imageLiteral(resourceName: "keyGlow.svg")
    
//    public static let imageCenter: (x: CGFloat, y: CGFloat) = (x: 38.3845, y: 37.790)
//    public static let imageSize: (x: CGFloat, y: CGFloat) = (x: 76.769, y: 89.745)
//    public static let imageCenterRelativeY = Key.imageCenter.y / Key.imageSize.y
    
    private lazy var keyImageView = UIImageView(image: Key.keyImage)
    private lazy var shadowImageView = UIImageView(image: Key.shadowImage)
    private lazy var glowImageView = UIImageView(image: Key.glowImage.withTintColor(color)) // color used after inited
    
    private lazy var noteLabel: UILabel = {
        let label = UILabel()
        label.text = String(Int(note) % Globals.activeKeymap.tuning)
        label.font = UIFont(name: "Copperplate", size: 22)
        label.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.51)
        label.frame = keyImageView.frame // by reference
        label.textAlignment = .center
        return label
      }()
    
    
    public var note: UInt8
    public var color: UIColor
    
    
    required init?(coder: NSCoder) { fatalError() }
    
    init(note: UInt8, color: UIColor) {
        //self.glowImageView = UIImageView(image: Key.glowImage.withTintColor(color))
        self.note = note
        self.color = color
        super.init(frame: CGRect(origin: .zero, size: Key.shadowImage.size))
        
        for view in [shadowImageView, keyImageView, glowImageView] {
            view.frame.origin.x = -view.frame.size.width / 2;
            view.frame.origin.y = -view.frame.size.height / 2;
        }
        shadowImageView.frame.origin.y += 10.5
        
        addSubview(shadowImageView)
        addSubview(keyImageView)
        addSubview(glowImageView)
        addSubview(noteLabel)
        
//        let circle = UIView(frame: CGRect(origin: self.frame.origin, size: CGSizeMake(85, 85)))
//        circle.frame.origin.x -= circle.frame.size.width / 2
//        circle.frame.origin.y -= circle.frame.size.height / 2
//        circle.layer.cornerRadius = circle.frame.size.width / 2
//        circle.backgroundColor = UIColor(white: 0, alpha: 0.2)
//        addSubview(circle)
    }
    
    convenience init() {
        self.init(note: 0, color: .clear)
    }
    
    public func assign(note: UInt8, color: UIColor) {
        self.glowImageView.image = Key.glowImage.withTintColor(color)
        self.note = note
        noteLabel.text = String(Int(note) % Globals.activeKeymap.tuning)
        self.color = color
    }
    
//    override func layoutSubviews() {
        // TODO: respond to keyboard zooming
        //noteLabel.frame.origin.x = self.frame.origin.x + self.frame.width/2.0 - noteLabel.frame.width/2.0
        //noteLabel.frame.origin.y = self.frame.origin.y + self.frame.height/2.0 - noteLabel.frame.height/2.0
//    }
    
    
    // user interaction change appearance
    
    public func activate(_ touch: UITouch, with event: UIEvent?) {
        for view in [keyImageView, glowImageView, noteLabel] {
            view.frame.origin.y = -view.frame.size.height / 2 + 4.5;
        }
    }
    public func deactivate() {
        for view in [keyImageView, glowImageView, noteLabel] {
            view.frame.origin.y = -view.frame.size.height / 2;
        }
    }
    
}

 
/*
 manual draw worksheet
 
 
+impl transformed uiview
 
+re-design key images: key, keyShadow, keyGlow
 
 new lets, manual draw
 impl draw position (new var `pressed`)
 
 lazy rendering (keyboard set key hidden on layout)
 
 
 rewrite hitTest use radius
 
 impl multiple-note touch (actually just increase radius, no dict needed)
 
 */


/**
 notes from SwiftSynth:
 `contentMode = .redraw`
 `didset if != oldvalue then self.setNeedDisplay()`
 */
