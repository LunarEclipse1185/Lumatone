//
//  KeyView.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/16.
//

import UIKit
import AVFoundation


class Key: UIView {
    
    public static let keyImage = #imageLiteral(resourceName: "key.svg")
    public static let shadowImage = #imageLiteral(resourceName: "keyShadow.svg")
    public static let glowImage = #imageLiteral(resourceName: "keyGlow.svg")
    
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
    
    
    var note: UInt8 = 0
    var color: UIColor = .clear
    
    var scale: CGFloat = 1.0 {
        didSet {
            // scaling
            for view in [keyImageView, glowImageView, noteLabel] {
                view.frame.size.width *= scale / oldValue
                view.frame.size.height *= scale / oldValue
            }
            noteLabel.font = noteLabel.font.withSize(22 * scale)
            
            // positioning
            setNeedsLayout()
        }
    }
    
    var pressed = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    
    required init?(coder: NSCoder) { fatalError() }
    
    init() {
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
    }
    
    func assign(note: UInt8, color: UIColor) {
        self.glowImageView.image = Key.glowImage.withTintColor(color)
        self.note = note
        noteLabel.text = String(Int(note) % Globals.activeKeymap.tuning)
        self.color = color
    }
    
    
    override func layoutSubviews() {
        // positioning
        for view in [keyImageView, glowImageView, noteLabel] {
            view.frame.origin.y = -view.frame.size.height / 2 + (pressed ? 4.5 : 0)
        }
    }
    
    
    func activate(_ touch: UITouch, with event: UIEvent?) {
        pressed = true
    }
    func deactivate() {
        pressed = false
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
