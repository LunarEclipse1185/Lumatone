//
//  ControlPanel.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/18.
//

import UIKit
import AVFoundation

class ControlPanel: UIView {
    required init(coder: NSCoder) { fatalError() }
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        
        addSubview(pitchBendControl)
        addSubview(velocityControl)
        
        addSubview(soundfontChooser)
        
        addSubview(presetPicker)
        addSubview(keymapPicker)
        addSubview(layoutPicker)
        
        addSubview(handle)
        
        // initial values of the controls
        // TODO: bad in that init values are separated
        pitchBendSlider.sendActions(for: .valueChanged)
        velocitySlider.sendActions(for: .valueChanged)
        presetPicker.sendAction(presetPicker.menu?.children[0] as! UIAction)
        keymapPicker.sendAction(keymapPicker.menu?.children[0] as! UIAction)
        layoutPicker.selectedSegmentIndex = 0
        layoutPicker.sendActions(for: .valueChanged)
    }
    
    override func layoutSubviews() {
        let w = frame.width
        let h = frame.height
        
        pitchBendControl.frame = CGRectMake(0.2 * h, 0.1 * h, 0.3 * h, 0.7 * h)
        velocityControl.frame = CGRectMake(0.6 * h, 0.1 * h, 0.3 * h, 0.7 * h)
        
        //soundfontChooser.frame = CGRectMake(w - 3.3 * h, 0.1 * h, 1.5 * h, 0.3 * h) // TODO:
        
        let height = 0.2 * h
        let width = 1.2 * h
        let spacing = (h - 3 * height) / 4
        for (i, view) in [layoutPicker, presetPicker, keymapPicker].enumerated() {
            view.frame = CGRectMake(w - width - spacing, CGFloat(i) * height + CGFloat(i+1) * spacing, width, height)
        }
        
        handle.frame = CGRectMake(0.85 * w, h, 0.08 * w, 0.03 * w)
    }
    
    
    // MARK: handle
    private lazy var handle = Handle()
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return handle.hitTest(handle.convert(point, from: self), with: event) ?? super.hitTest(point, with: event)
    }
    
    // MARK: Pitch Bend
    private lazy var pitchBendControl = LabeledControl("Pitch Bend", control: pitchBendSlider, labelPosition: .bottom)
    private lazy var pitchBendSlider = {
        let pbs = UISlider()
        pbs.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        pbs.minimumValue = -200.0 // cents
        pbs.maximumValue = 200.0
        pbs.setValue(0, animated: false)
        pbs.addTarget(self, action: #selector(sendPitchBend), for: .valueChanged)
        pbs.addTarget(self, action: #selector(elasticAnimation), for: .touchUpInside)
        pbs.addTarget(self, action: #selector(elasticAnimation), for: .touchUpOutside)
        pbs.addTarget(self, action: #selector(stopAnimation), for: .touchDown)
        return pbs
    }()
    @objc private func sendPitchBend() {
        AudioEngine.pitchBendChangedNotif.post(value: pitchBendSlider.value)
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
    
    
    // MARK: Velocity
    private lazy var velocityControl = LabeledControl("Velocity", control: velocitySlider, labelPosition: .bottom)
    private lazy var velocitySlider = {
        let vs = UISlider()
        vs.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        vs.minimumValue = 0
        vs.maximumValue = 127
        vs.setValue(64, animated: false)
        vs.addTarget(self, action: #selector(sendVelocity), for: .valueChanged)
        return vs
    }()
    @objc private func sendVelocity() {
        Keyboard.velocityChangedNotif.post(value: UInt8(velocitySlider.value))
    }
    
    
    // MARK: Tickbox Settings
    
    
    // MARK: Soundfont (TODO)
    private var soundfontChooser = SoundfontChooser() // TODO

    
    // MARK: Preset
    private lazy var presetPicker = {
        let picker = UIButton(configuration: .bordered())
        picker.setTitleColor(.white, for: .highlighted)
        picker.setTitleColor(.white, for: .normal)
        picker.menu = UIMenu(options: .singleSelection, children: ((0...127) as ClosedRange<UInt8>).map { index in
            UIAction(title: "Preset " + String(index)) { _ in
                AudioEngine.presetIndexChangedNotif.post(value: index)
            }
        })
        picker.showsMenuAsPrimaryAction = true
        picker.changesSelectionAsPrimaryAction = true // disable to manually set title
        return picker
    }()
    
    
    // MARK: Keymap
    private lazy var keymapPicker = {
        let picker = UIButton(configuration: .bordered())
        picker.setTitleColor(.white, for: .highlighted)
        picker.setTitleColor(.white, for: .normal)
        picker.menu = UIMenu(options: .singleSelection, children: Keymap.builtin.map { keymap in
            UIAction(title: keymap.name) { _ in
                Keyboard.keymapChangedNotif.post(value: keymap)
                AudioEngine.tuningChangedNotif.post(value: keymap.tuning)
            }
        })
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
        /// plan: "Open..." segment when pressed open a file select dialog, add a segment before itself and select the loaded keymap
    }()
    */
    
    
    // MARK: Layout (TODO)
    private var layoutPicker = {
        let sc = UISegmentedControl(frame: .zero, actions: [
            UIAction(title: "Lumatone", image: nil) { _ in
                // switch
            },
            UIAction(title: "InfHex", image: nil) { _ in
                // switch
            }
        ])
        return sc
    }()
    
}
