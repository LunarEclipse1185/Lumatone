//
//  ControlPanel.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/18.
//

import UIKit
import AVFoundation

class ControlPanel: UIView {
    
    private var audioEngine: AudioEngine
    private var keyboard: Keyboard // associated keyboard
    
    required init(coder: NSCoder) { fatalError() }
    
    init(_ engine: AudioEngine, _ keyboard: Keyboard) {
        self.audioEngine = engine
        self.keyboard = keyboard
        
        super.init(frame: .zero)
        
        self.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        
        addSubview(pitchBendSlider)
        addSubview(velocitySlider)
        addSubview(pitchBendLabel)
        addSubview(masterGainLabel)
        
        addSubview(soundfontChooser)
        addSubview(presetPicker)
        addSubview(keymapPicker)
        addSubview(layoutPicker)
    }
    
    override func layoutSubviews() {
        let w = self.frame.width
        let h = self.frame.height
        
        pitchBendSlider.frame = CGRectMake(0.2 * h, 0.1 * h, 0.3 * h, 0.7 * h)
        velocitySlider.frame = CGRectMake(0.8 * h, 0.1 * h, 0.3 * h, 0.7 * h)
        
        pitchBendLabel.frame = CGRectMake(0.1 * h, 0.75 * h, 0.5 * h, 0.2 * h)
        masterGainLabel.frame = CGRectMake(0.7 * h, 0.75 * h, 0.5 * h, 0.2 * h)
        
        soundfontChooser.frame = CGRectMake(w - 3.3 * h, 0.1 * h, 1.5 * h, 0.3 * h)
        presetPicker.frame = CGRectMake(w - 3.3 * h, 0.6 * h, 1.5 * h, 0.3 * h)
        layoutPicker.frame = CGRectMake(w - 1.6 * h, 0.1 * h, 1.5 * h, 0.3 * h)
        keymapPicker.frame = CGRectMake(w - 1.6 * h, 0.6 * h, 1.5 * h, 0.3 * h)
    }
    
    
    // components
    
    private lazy var pitchBendLabel = {
        let label = UILabel()
        label.text = "Pitch Bend"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    private lazy var masterGainLabel = {
        let label = UILabel()
        label.text = "Velocity"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    
    private lazy var pitchBendSlider = {
        let pbs = UISlider()
        pbs.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        pbs.minimumValue = -200.0 // cents
        pbs.maximumValue = 200.0
        pbs.setValue(Globals.pitchBend, animated: false)
        pbs.addTarget(self, action: #selector(sendPitchBend), for: .valueChanged)
        pbs.addTarget(self, action: #selector(elasticAnimation), for: .touchUpInside)
        pbs.addTarget(self, action: #selector(elasticAnimation), for: .touchUpOutside)
        pbs.addTarget(self, action: #selector(stopAnimation), for: .touchDown)
        return pbs
    }()
    @objc private func sendPitchBend() {
        Globals.pitchBend = pitchBendSlider.value
        audioEngine.setPitchBend(pitchBendSlider.value)
    }
    @objc private func stopAnimation() {
        timer?.invalidate()
    }
    var timer: Timer?
    @objc private func elasticAnimation() {
        let div = 10 // resolution of the animation
        var count = 0
        let current = self.pitchBendSlider.value
        let mid = (self.pitchBendSlider.maximumValue + self.pitchBendSlider.minimumValue) / 2
        
        func cubic(_ x: Float) -> Float {
            return (1-x)*(1-x)*(1-x)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5/Double(div), repeats: true) { timer in
            count += 1
            
            let val = cubic(Float(count)/Float(div)) * (current - mid) + mid
            self.pitchBendSlider.setValue(val, animated: true)
            self.sendPitchBend()
            
            if count >= div {
                timer.invalidate()
            }
        }
    }
    
    
    private lazy var velocitySlider = {
        let vs = UISlider()
        vs.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        vs.minimumValue = 0
        vs.maximumValue = 127
        vs.setValue(Float(Globals.globalVelocity), animated: false)
        vs.addTarget(self, action: #selector(sendMasterGain), for: .valueChanged)
        return vs
    }()
    @objc private func sendMasterGain() {
        Globals.globalVelocity = UInt8(clamping: Int(velocitySlider.value))
    }
    
    
    private var soundfontChooser = SoundfontChooser() // TODO

    
    
    private lazy var presetPicker = {
        let picker = UIButton(configuration: .bordered())
        //picker.setTitleColor(.lightText, for: .normal) // TODO: for all state, contrastive color
        picker.menu = UIMenu(options: .singleSelection, children: ((0...127) as ClosedRange<UInt8>).map { index in
            UIAction(title: "Preset " + String(index)) { _ in
                Globals.presetIndex = index
                self.audioEngine.loadInstrument(presetIndex: index)
            }
        })
        picker.sendAction(picker.menu?.children[Int(Globals.presetIndex)] as! UIAction)
        picker.showsMenuAsPrimaryAction = true
        picker.changesSelectionAsPrimaryAction = true // disable to manually set title
        return picker
    }()
    
    
    private lazy var keymapPicker = {
        let picker = UIButton(configuration: .bordered())
        picker.menu = UIMenu(options: .singleSelection, children: Keymap.builtin.map { keymap in
            UIAction(title: keymap.name) { _ in
                Globals.activeKeymap = keymap
                self.keyboard.changeKeymap(keymap)
            }
        })
        keyboard.changeKeymap(Globals.activeKeymap) // default keymap
        picker.showsMenuAsPrimaryAction = true
        picker.changesSelectionAsPrimaryAction = true
        return picker
    }()
    
    /* // SegmentControl version
    private lazy var keymapPicker = {
        //UILabel.appearance(whenContainedInInstancesOf: [UISegmentedControl.self]).numberOfLines = 0 // multiline text
        let sc = UISegmentedControl(frame: .zero, actions: Keymap.builtin.map { keymap in
            UIAction(title: keymap.name) { _ in
                Globals.activeKeymap = keymap
                self.keyboard.changeKeymap(keymap)
            }
        })
        sc.selectedSegmentIndex = Keymap.builtin.firstIndex { keymap in
            keymap.name == Globals.activeKeymap.name
        } ?? -1
        if let action = sc.actionForSegment(at: sc.selectedSegmentIndex) {
            sc.sendAction(action)
        }
        return sc
        
        // TODO: add a special segment for keymap loaded from file
        /// plan: "Open..." segment when tapped open a file select dialog, add a segment before itself and select the loaded keymap
    }()
    */
    
    
    private var layoutPicker = {
        let sc = UISegmentedControl(frame: .zero, actions: [
            UIAction(title: "Lumatone", image: nil) { _ in
                // switch
            }
        ])
        return sc
    }()
    
}
