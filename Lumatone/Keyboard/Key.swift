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
    
    // components
    private lazy var keyImageView = UIImageView(image: Key.keyImage)
    private lazy var shadowImageView = UIImageView(image: Key.shadowImage)
    private lazy var glowImageView = UIImageView(image: Key.glowImage.withTintColor(color)) // color used after inited
    
    private lazy var noteLabel: UILabel = {
        let label = UILabel(frame: keyImageView.frame)
        return label
      }()
    
    // states
    var note: UInt8 = 0
    var color: UIColor = .clear
    var labelMapping: LabelMapping = { _ in NSAttributedString() }
    
    var pressed = false {
        didSet {
            if pressed == oldValue { return }
            
            setNeedsLayout()
        }
    }
    
    var scale: CGFloat = 1.0 {
        didSet {
            if scale == oldValue { return }
            
            // scaling
            for view in [keyImageView, glowImageView, noteLabel] {
                view.frame.size.width *= scale / oldValue
                view.frame.size.height *= scale / oldValue
            }
            // scaling label, copying all attrs
            updateLabel()
            /*let newText = noteLabel.attributedText?.mutableCopy() as! NSMutableAttributedString
            noteLabel.attributedText?.enumerateAttributes(in: NSRange(location: 0, length: noteLabel.attributedText?.length ?? 0)) { dict, range, _ in
                for (key, value) in dict {
                    if let font = value as? UIFont {
                        newText.setAttributes([.font : font.withSize(font.pointSize * scale / oldValue)], range: range)
                        continue
                    }
                    newText.setAttributes([key : value], range: range)
                }
            }
            noteLabel.attributedText = newText*/
            
                    
            // positioning
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
    
    func assign(note: UInt8, color: UIColor, labelMapping: @escaping LabelMapping) {
        self.glowImageView.image = Key.glowImage.withTintColor(color)
        self.note = note
        self.color = color
        self.labelMapping = labelMapping
        updateLabel()
    }
    
    private func updateLabel() {
        NoteLabel.setFontSize(scale * 24)
        noteLabel.attributedText = labelMapping(note)
        noteLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.51)
        noteLabel.textAlignment = .center
    }
    
    override func layoutSubviews() {
        // positioning
        for view in [keyImageView, glowImageView, noteLabel] {
            view.frame.origin.y = -view.frame.size.height / 2 + (pressed ? 4.5 : 0)
        }
    }
}
