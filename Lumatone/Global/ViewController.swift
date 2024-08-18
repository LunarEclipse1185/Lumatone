//
//  ViewController.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/15.
//

import UIKit

class ViewController: UIViewController {
    
    private var audioEngine: AudioEngine!
    private var controlPanel: ControlPanel!
    private var keyboard: Keyboard!
    
    private var folded = false
    
    override func viewDidLoad() {
        audioEngine = AudioEngine()
        audioEngine.setupEngine()
        keyboard = Keyboard(audioEngine)
        controlPanel = ControlPanel(audioEngine, keyboard)
        
        super.viewDidLoad()
        
        let sframe = view.safeAreaLayoutGuide.layoutFrame
        controlPanel.frame = CGRectMake(sframe.minX, sframe.minY, sframe.width, 0.25 * sframe.height)
        keyboard.frame = CGRectMake(sframe.minX, sframe.minY + 0.25 * sframe.height, sframe.width, 0.75 * sframe.height)
        
        view.addSubview(keyboard)
        view.addSubview(controlPanel)
        
        // notification
        NotificationCenter.default.addObserver(forName: .panelHandleSwitched, object: nil, queue: nil, using: switchLayout(_:))
    }
    
    private func switchLayout(_: Notification) {
        let sframe = view.safeAreaLayoutGuide.layoutFrame
        folded = !folded
        controlPanel.frame.origin.y = folded ? -controlPanel.frame.height : 0
        
        keyboard.frame.origin.y = folded ? 0 : controlPanel.frame.height
        keyboard.frame.size.height = folded ? sframe.height : sframe.height - controlPanel.frame.height
    }
}
