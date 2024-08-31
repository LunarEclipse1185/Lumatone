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
    var color: UIColor = .clear {
        didSet { glowImageView.image = Key.glowImage.withTintColor(color) }
    }
    var labelMapping: LabelMapping = { _ in NSAttributedString() } {
        didSet { updateLabel() }
    }
    
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
            for view in subviews {
                view.frame.size.width *= scale / oldValue
                view.frame.size.height *= scale / oldValue
            }
            // scaling label font
            updateLabel()
            // positioning
            setNeedsLayout()
        }
    }
    
    
    required init?(coder: NSCoder) { fatalError() }
    
    init() {
        super.init(frame: CGRect(origin: .zero, size: Key.shadowImage.size))
        addSubview(shadowImageView)
        addSubview(keyImageView)
        addSubview(glowImageView)
        addSubview(noteLabel)
    }
    
    convenience init(note: UInt8, color: UIColor, labelMapping: @escaping LabelMapping) {
        self.init()
        assign(note: note, color: color, labelMapping: labelMapping)
    }
    
    func assign(note: UInt8, color: UIColor, labelMapping: @escaping LabelMapping) {
        self.note = note
        self.color = color
        self.labelMapping = labelMapping
    }
    func assign(labelMapping: @escaping LabelMapping) {
        self.labelMapping = labelMapping
    }
    
    private func updateLabel() {
        NoteLabel.setFontSize(scale * 24)
        noteLabel.attributedText = labelMapping(note)
        noteLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.51)
        noteLabel.textAlignment = .center
    }
    
    override func layoutSubviews() {
        // positioning
        for view in subviews {
            view.frame.origin.x = -view.frame.size.width / 2;
            view.frame.origin.y = -view.frame.size.height / 2 + (pressed && view !== shadowImageView ? 4.5 : 0) * scale
        }
        shadowImageView.frame.origin.y += 10.5 * scale
    }
}
