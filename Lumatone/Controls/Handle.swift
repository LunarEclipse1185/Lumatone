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
        // TODO: design handle UI
        
        // userdefault data read by ViewController
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        NotificationCenter.default.post(name: .panelHandleSwitched, object: self)
        UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: "controlPanelFolded_Bool"), forKey: "controlPanelFolded_Bool")
    }
}
