//
//  ViewController.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/15.
//

import UIKit

class ViewController: UIViewController {
    
    private var audioEngine: AudioEngine
    private var controlPanel: ControlPanel
    private var keyboard: Keyboard
    
    
    required init?(coder: NSCoder) {
        audioEngine = AudioEngine()
        audioEngine.setupEngine()
        keyboard = Keyboard(audioEngine)
        controlPanel = ControlPanel(audioEngine, keyboard)
        
        super.init(coder: coder)
    }
    
    override init(nibName: String?, bundle: Bundle?) {
        audioEngine = AudioEngine()
        audioEngine.setupEngine()
        keyboard = Keyboard(audioEngine)
        controlPanel = ControlPanel(audioEngine, keyboard)
        
        super.init(nibName: nibName, bundle: bundle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sframe = view.safeAreaLayoutGuide.layoutFrame
        
        controlPanel.frame = CGRectMake(sframe.minX, sframe.minY, sframe.width, 0.25 * sframe.height)
        
        keyboard.frame = CGRectMake(sframe.minX, sframe.minY + 0.25 * sframe.height, sframe.width, 0.75 * sframe.height)
        
        view.addSubview(controlPanel)
        view.addSubview(keyboard)
    }
}
