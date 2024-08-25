//
//  LabeledControl.swift
//  Lumatone
//
//  Created by SH BU on 2024/8/19.
//

import UIKit

class LabeledControl: UIView {
    var label: UILabel
    var control: UIControl
    var position: LabeledControlConfiguration
    
    required init?(coder: NSCoder) { fatalError() }
    
    init(_ name: String, control: UIControl, labelPosition position: LabeledControlConfiguration) {
        self.label = UILabel()
        label.text = name
        label.font = .systemFont(ofSize: 18)
        label.textColor = .lightGray
        label.textAlignment = .center
        self.control = control
        self.position = position
        
        super.init(frame: .zero)
        
        addSubview(control)
        addSubview(label)
    }
    
    override func layoutSubviews() {
        control.frame.origin = .zero
        control.frame.size = self.frame.size
        label.frame.size = label.intrinsicContentSize
        if position == .bottom || position == .top {
            label.frame.origin.x = frame.width / 2 - label.intrinsicContentSize.width / 2
        }
        if position == .left || position == .right {
            label.frame.origin.y = frame.height / 2 - label.intrinsicContentSize.height / 2
        }
        
        let padding: CGFloat = 5.0
        switch position {
        case .bottom:
            label.frame.origin.y = frame.height + padding
        case .top:
            label.frame.origin.y = -label.frame.height - padding
        case .left:
            label.frame.origin.x = -label.frame.width - padding
        case .right:
            label.frame.origin.x = frame.width + padding
        }
    }
    
}

enum LabeledControlConfiguration {
    case bottom
    case top
    case left
    case right
}
