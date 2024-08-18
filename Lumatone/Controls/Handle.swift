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
        backgroundColor = .gray
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        NotificationCenter.default.post(Notification(name: .panelHandleSwitched))
    }
}
