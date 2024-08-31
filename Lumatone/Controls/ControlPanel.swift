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
        
        addSubview(soundfontChooserControl)
        addSubview(presetPickerControl)
        addSubview(keymapPickerControl)
        
        addSubview(settingsButton)
        addSubview(helpButton)
        
        addSubview(handle)
        
        // observers
        NotificationCenter.default.addObserver(forName: .presetNamesParsed, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.presetPicker.menu = self.generatePresetMenu()
            }
        }
    }
    
    override func layoutSubviews() {
        let w = frame.width
        let h = frame.height
        
        pitchBendControl.frame = CGRectMake(0.2 * h, 0.1 * h, 0.3 * h, 0.7 * h)
        velocityControl.frame = CGRectMake(0.7 * h, 0.1 * h, 0.3 * h, 0.7 * h)
        
        let pickersWidth = 1.1 * h
        layoutV([soundfontChooserControl, presetPickerControl, keymapPickerControl],
                inRect: CGRectMake(w / 2 - pickersWidth / 2, 0, pickersWidth, h),
                elementHeight: 31)
        let buttonsSideLen = 0.2 * h
        layoutV([settingsButton, helpButton],
                inRect: CGRectMake(w - 2 * buttonsSideLen, 0, buttonsSideLen, h),
                elementHeight: buttonsSideLen)
        
        handle.frame = CGRectMake(0.85 * w, h, 0.08 * w, 0.03 * w)
    }
    private func layoutV(_ views: [UIView], inRect rect: CGRect, spacing s_: CGFloat! = nil, elementHeight h_: CGFloat! = nil) {
        // provide at least 1 data for layout
        guard s_ != nil || h_ != nil else { fatalError("layoutV invalid arguments") }
        let spacing = s_ ?? (rect.height - CGFloat(views.count) * h_) / CGFloat(views.count + 1)
        let height = h_ ?? (rect.height - CGFloat(views.count + 1) * s_) / CGFloat(views.count)
        for (i, view) in views.enumerated() {
            view.frame = CGRectMake(rect.minX, CGFloat(i) * height + CGFloat(i+1) * spacing, rect.width, height)
        }
    }
    
    // MARK: Labeled Controls
    private lazy var pitchBendControl = LabeledControl("Pitch Bend", control: pitchBendSlider, labelPosition: .bottom)
    private lazy var velocityControl = LabeledControl("Velocity", control: velocitySlider, labelPosition: .bottom)
    
//    private lazy var multiPressToggleControl = LabeledControl("Multi-Press", control: multiPressToggle, labelPosition: .left)
    
    private lazy var soundfontChooserControl = LabeledControl("Soundfont:   ", control: soundfontChooser, labelPosition: .left)
    private lazy var presetPickerControl = LabeledControl("Preset:      ", control: presetPicker, labelPosition: .left)
    private lazy var keymapPickerControl = LabeledControl("Keymap:      ", control: keymapPicker, labelPosition: .left)
//    private lazy var layoutPickerControl = LabeledControl("Layout:      ", control: layoutPicker, labelPosition: .left)
    
    // MARK: navigator buttons
    
    private lazy var settingsButton = {
        let button = UIButton(configuration: .bordered(), primaryAction: UIAction { _ in
            NotificationCenter.default.post(name: .showSettings, object: self)
        })
        button.setImage(UIImage(systemName: "gearshape"), for: .normal)
        button.setImage(UIImage(systemName: "gearshape"), for: .highlighted)
        return button
    }()
    
    private lazy var helpButton = {
        let button = UIButton(configuration: .bordered(), primaryAction: UIAction { _ in
            NotificationCenter.default.post(name: .showHelp, object: self)
        })
        button.setImage(UIImage(systemName: "questionmark"), for: .normal)
        button.setImage(UIImage(systemName: "questionmark"), for: .highlighted)
        return button
    }()
    
    
    // MARK: Handle
    private lazy var handle = Handle()
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return handle.hitTest(handle.convert(point, from: self), with: event) ?? super.hitTest(point, with: event)
    }
    
    
    // MARK: Keymap
    private lazy var keymapPicker = {
        let picker = UIButton(configuration: .bordered())
        picker.menu = UIMenu(options: .singleSelection, children: Keymap.builtin.map { keymap in
            UIAction(title: keymap.name) { _ in
                Keyboard.keymapChangedNotif.post(value: keymap)
                AudioEngine.tuningChangedNotif.post(value: keymap.tuning)
                UserDefaults.standard.set(keymap.name, forKey: "keymapName_String")
            }
        })
        if let index = Keymap.searchBuiltinKeymapIndex(UserDefaults.standard.string(forKey: "keymapName_String") ?? "Harmonic Table") {
            (picker.menu?.children[index] as! UIAction).state = .on
        }
        picker.setTitleColor(.white, for: .highlighted)
        picker.setTitleColor(.white, for: .normal)
        picker.showsMenuAsPrimaryAction = true
        picker.changesSelectionAsPrimaryAction = true
        return picker
    }()
    
    
    // MARK: Soundfont
    var soundfontUrl: URL = AudioEngine.UserDefaultsResolveSoundbankUrl()
    private lazy var soundfontChooser = {
        let button = UIButton(configuration: .bordered(), primaryAction: UIAction { [weak self] _ in
            NotificationCenter.default.post(name: .showDocumentPicker, object: self)
        })
        button.setTitle(soundfontUrl.lastPathComponent, for: .normal)
        button.setTitle(soundfontUrl.lastPathComponent, for: .highlighted)
        return button
    }()
    func recievedFileUrl(_ url: URL) {
        // save file url
        if let bookmark = try? url.bookmarkData() {
            soundfontUrl = url
            UserDefaults.standard.set(bookmark, forKey: "soundfontFileUrl_Data")
        } else {
            print("file moved during code execution. making no changes")
            return
        }
        // change button title
        soundfontChooser.setTitle(soundfontUrl.lastPathComponent, for: .normal)
        soundfontChooser.setTitle(soundfontUrl.lastPathComponent, for: .highlighted)
        // load new soundfont
        self.presetPicker.menu = self.generatePresetMenu()
        NotificationCenter.default.post(name: .soundfontChanged, object: self)
    }

    
    // MARK: Preset
    private lazy var presetPicker = {
        let picker = UIButton(configuration: .bordered())
        picker.menu = generatePresetMenu()
        (picker.menu?.children[UserDefaults.standard.integer(forKey: "presetMenuIndex_Int")] as! UIAction).state = .on
        picker.setTitleColor(.white, for: .highlighted)
        picker.setTitleColor(.white, for: .normal)
        picker.showsMenuAsPrimaryAction = true
        picker.changesSelectionAsPrimaryAction = true // disable to manually set title
        return picker
    }()
    private func generatePresetMenu() -> UIMenu {
        let files = try! FileManager.default.contentsOfDirectory(at: URL.documentsDirectory, includingPropertiesForKeys: nil).map { $0.lastPathComponent }
        let namesUrl = URL.documentsDirectory.appending(component: soundfontUrl.lastPathComponent.replacing(".sf2", with: ".presetnames"))
        var names: [SF2Parser.Name]?
        // read or generate
        if files.contains(namesUrl.lastPathComponent) {
            if let data = try? Data(contentsOf: namesUrl) {
                names = SF2Parser.namesObject(from: data)
            } // else leave names == nil
        }
        if names == nil {
            names = parsePresetNames(soundfontUrl)
            guard names != nil else { 
                return UIMenu(options: .singleSelection, children: [UIAction(title: "Menu creation failed") { _ in }])
            }
            let success = nil != (try? SF2Parser.namesData(from: names!).write(to: namesUrl))
            print(success ? "generated new .presetnames file" : "write new .presetnames file failed")
        }
        // update menu
        return UIMenu(options: .singleSelection, children: names!.enumerated().map { (i, name) in
            let (b, p, n) = name
            return UIAction(title: "\(b):\(p) \(n)") { _ in
                AudioEngine.presetIndexChangedNotif.post(value: UInt16(b) << 8 + UInt16(p)) // bank:preset
                UserDefaults.standard.set(UInt16(b) << 8 + UInt16(p), forKey: "presetIndex_Int")
                UserDefaults.standard.set(i, forKey: "presetMenuIndex_Int")
            }
        })
    }
    private func parsePresetNames(_ url: URL) -> [SF2Parser.Name]? {
        if let data = try? Data(contentsOf: url) {
            let parser = SF2Parser(data: data)
            let _ = parser.parse(options: [.parsePresetNames])
//            if !status {
//                print("[parser error]: \(parser.log)")
//                return false
//            }
            let sorted = SF2Parser.sortNames(parser.namesParsed)
            return sorted
        } else {
            print("read file denied: \(url)")
            return nil
        }
    }
    
    
    // MARK: Pitch Bend
    private lazy var pitchBendSlider = {
        let pbs = UISlider()
        pbs.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        pbs.minimumValue = -200.0 // cents
        pbs.maximumValue = 200.0
        pbs.setValue(0, animated: false)
        pbs.addTarget(self, action: #selector(sendPitchBend), for: .valueChanged)
        pbs.addTarget(self, action: #selector(elasticAnimation), for: .touchUpInside)
        pbs.addTarget(self, action: #selector(elasticAnimation), for: .touchUpOutside)
        pbs.addTarget(self, action: #selector(cancelAnimation), for: .touchDown)
//        pbs.addTarget(timer, action: #selector(timer.invalidate), for: .touchDown) // doesnt work. WHY???
        return pbs
    }()
    @objc private func sendPitchBend() {
        AudioEngine.pitchBendChangedNotif.post(value: pitchBendSlider.value)
    }
    @objc private func cancelAnimation() {
        timer?.invalidate()
    }
    var timer: Timer?
    @objc private func elasticAnimation() {
        let div = 10 // resolution of the animation
        var count = 0
        let current = self.pitchBendSlider.value
        let mid = (self.pitchBendSlider.maximumValue + self.pitchBendSlider.minimumValue) / 2
        
        let cubic = { (x: Float) in (1-x)*(1-x)*(1-x) }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5/Double(div), repeats: true) { timer in
            count += 1
            let val = cubic(Float(count)/Float(div)) * (current - mid) + mid
            self.pitchBendSlider.setValue(val, animated: true)
            self.sendPitchBend()
            if count >= div { timer.invalidate() }
        }
    }
    
    
    // MARK: Velocity
    private lazy var velocitySlider = {
        let vs = UISlider()
        vs.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        vs.minimumValue = 0
        vs.maximumValue = 127
        vs.setValue(UserDefaults.standard.object(forKey: "velocity_Float") as? Float ?? 64, animated: false)
        vs.addTarget(self, action: #selector(sendVelocity), for: .valueChanged)
        return vs
    }()
    @objc private func sendVelocity() {
        Keyboard.velocityChangedNotif.post(value: UInt8(velocitySlider.value))
        UserDefaults.standard.set(velocitySlider.value, forKey: "velocity_Float")
    }
    
}
