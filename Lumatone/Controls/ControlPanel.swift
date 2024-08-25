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
        
        addSubview(multiPressToggleControl)
        addSubview(soundfontChooserControl)
        
        addSubview(presetPickerControl)
        addSubview(keymapPickerControl)
        addSubview(layoutPickerControl)
        
        addSubview(handle)
        
        initialize()
        
        // observers
        NotificationCenter.default.addObserver(forName: .presetNamesParsed, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.updatePresetPickerMenu()
            }
        }
    }
    
    private func initialize() {
        // initial values of the controls
        // numeric api returns 0 if key does not exist
        pitchBendSlider.setValue(UserDefaults.standard.float(forKey: "pitchBend_Float"), animated: false)
        pitchBendSlider.sendActions(for: .valueChanged)
        
        velocitySlider.setValue(UserDefaults.standard.object(forKey: "velocity_Float") as? Float ?? 64, animated: false)
        velocitySlider.sendActions(for: .valueChanged)
        
        multiPressToggle.setOn(UserDefaults.standard.bool(forKey: "multiPress_Bool"), animated: false)
        multiPressToggle.sendActions(for: .valueChanged)
        
        soundfontUrl = AudioEngine.UserDefaultsResolveSoundbankUrl()
        soundfontChooser.setTitle(soundfontUrl?.lastPathComponent, for: .normal)
        soundfontChooser.setTitle(soundfontUrl?.lastPathComponent, for: .highlighted)
        updatePresetPickerMenu()
        presetPicker.sendAction(presetPicker.menu?.children[UserDefaults.standard.integer(forKey: "presetMenuIndex_Int")] as! UIAction)
        
        if let index = Keymap.searchBuiltinKeymap(UserDefaults.standard.string(forKey: "keymapName_String") ?? "Harmonic Table") { // change this when custom file support
            keymapPicker.sendAction(keymapPicker.menu?.children[index] as! UIAction)
        } else { // simulate choosing a file
        }
        
        layoutPicker.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "layoutIndex_Int")
        layoutPicker.sendActions(for: .valueChanged)
    }
    
    override func layoutSubviews() {
        let w = frame.width
        let h = frame.height
        
        pitchBendControl.frame = CGRectMake(0.2 * h, 0.1 * h, 0.3 * h, 0.7 * h)
        velocityControl.frame = CGRectMake(0.7 * h, 0.1 * h, 0.3 * h, 0.7 * h)
        
        let height = 31.0
        let width = 1.1 * h
        let n = 3.0 // actually integer
        let spacing = (h - n * height) / (n+1)
        for (i, view) in [layoutPickerControl, presetPickerControl, keymapPickerControl].enumerated() {
            view.frame = CGRectMake(w / 2 - width / 2, CGFloat(i) * height + CGFloat(i+1) * spacing, width, height)
        }
        for (i, view) in [multiPressToggleControl, soundfontChooserControl].enumerated() {
            view.frame = CGRectMake(w - width - spacing, CGFloat(i) * height + CGFloat(i+1) * spacing,
                                    width, height)
        }
        
        handle.frame = CGRectMake(0.85 * w, h, 0.08 * w, 0.03 * w)
    }
    
    // MARK: Labeled Controls
    private lazy var pitchBendControl = LabeledControl("Pitch Bend", control: pitchBendSlider, labelPosition: .bottom)
    private lazy var velocityControl = LabeledControl("Velocity", control: velocitySlider, labelPosition: .bottom)
    
    private lazy var multiPressToggleControl = LabeledControl("Multi-Press", control: multiPressToggle, labelPosition: .left)
    private lazy var soundfontChooserControl = LabeledControl("Change Soundfont", control: soundfontChooser, labelPosition: .left)
    
    private lazy var presetPickerControl = LabeledControl("Preset:      ", control: presetPicker, labelPosition: .left)
    private lazy var keymapPickerControl = LabeledControl("Keymap:      ", control: keymapPicker, labelPosition: .left)
    private lazy var layoutPickerControl = LabeledControl("Layout:      ", control: layoutPicker, labelPosition: .left)
    
    
    // MARK: Handle
    private lazy var handle = Handle()
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return handle.hitTest(handle.convert(point, from: self), with: event) ?? super.hitTest(point, with: event)
    }
    
    
    // MARK: MultiPress Toggle
    private lazy var multiPressToggle = {
        let toggle = UISwitch()
        toggle.addTarget(self, action: #selector(sendMultiPressSetting), for: .valueChanged)
        return toggle
    }()
    @objc func sendMultiPressSetting(sender: UISwitch) {
        NotificationCenter.default.post(name: .multiPressChanged, object: nil, userInfo: ["value": sender.isOn])
        UserDefaults.standard.set(sender.isOn, forKey: "multiPress_Bool")
    }
    
    
    // MARK: Keymap
    private lazy var keymapPicker = {
        let picker = UIButton(configuration: .bordered())
        picker.setTitleColor(.white, for: .highlighted)
        picker.setTitleColor(.white, for: .normal)
        picker.menu = UIMenu(options: .singleSelection, children: Keymap.builtin.map { keymap in
            UIAction(title: keymap.name) { _ in
                Keyboard.keymapChangedNotif.post(value: keymap)
                AudioEngine.tuningChangedNotif.post(value: keymap.tuning)
                UserDefaults.standard.set(keymap.name, forKey: "keymapName_String")
            }
        })
        picker.showsMenuAsPrimaryAction = true
        picker.changesSelectionAsPrimaryAction = true
        return picker
    }()
    
    
    // MARK: Layout (TODO)
    private lazy var layoutPicker = {
        let sc = UISegmentedControl(frame: .zero, actions: [
            UIAction(title: "Lumatone", image: nil) { _ in
                // switch
                UserDefaults.standard.set(0, forKey: "layoutIndex_Int")
            },
            UIAction(title: "InfHex", image: nil) { _ in
                // switch
                UserDefaults.standard.set(1, forKey: "layoutIndex_Int")
            }
        ])
        return sc
    }()
    
    
    // MARK: Soundfont
    var soundfontUrl: URL?
    var showDocumentPicker: (() -> ())?
    private lazy var soundfontChooser = {
        let button = UIButton(configuration: .bordered(), primaryAction: UIAction { [weak self] _ in
            self?.showDocumentPicker?() // send message to viewController
        })
        button.setTitle("Choose file", for: .normal)
        button.setTitle("Choose file", for: .highlighted)
        return button
    }()
    func linkDocumentPicker(_ show: @escaping () -> ()) {
        showDocumentPicker = show
    }
    func recievedFileUrl(_ url: URL) {
        // save file url
        do {
            UserDefaults.standard.set(try url.bookmarkData(), forKey: "soundfontFileUrl_Data")
            soundfontUrl = url
        } catch {
            print("file moved during code execution, using builtin soundfont")
            do {
                soundfontUrl = Bundle.main.url(forResource: "YamahaGrand", withExtension: "sf2") // should not be nil
                UserDefaults.standard.set(try soundfontUrl?.bookmarkData(), forKey: "soundfontFileUrl_URL")
            } catch {
                print("create bookmark for builtin soundfont failed")
                soundfontUrl = nil
            }
        } // TODO: this is extra work. dont use default. dont set userdefaults at all
        // change button title
        soundfontChooser.setTitle(soundfontUrl?.lastPathComponent, for: .normal)
        soundfontChooser.setTitle(soundfontUrl?.lastPathComponent, for: .highlighted)
        // load new soundfont
        updatePresetPickerMenu()
        NotificationCenter.default.post(name: .soundfontChanged, object: self)
    }

    
    // MARK: Preset
    private lazy var presetPicker = {
        let picker = UIButton(configuration: .bordered())
        picker.setTitleColor(.white, for: .highlighted)
        picker.setTitleColor(.white, for: .normal)
//        picker.menu = UIMenu(options: .singleSelection, children: ((0...127) as ClosedRange<UInt8>).map { index in
//            UIAction(title: "Preset 0:" + String(index)) { _ in
//                AudioEngine.presetIndexChangedNotif.post(value: UInt16(index)) // bank number 0
//                UserDefaults.standard.set(index, forKey: "presetIndex_Int")
//            }
//        })
        picker.menu = UIMenu(options: .singleSelection, children: [
            UIAction(title: "No soundfont") { _ in }
        ])
        picker.showsMenuAsPrimaryAction = true
        picker.changesSelectionAsPrimaryAction = true // disable to manually set title
        return picker
    }()
    private func updatePresetPickerMenu() {
        guard let url = soundfontUrl else { return }
        // TODO: check if names file exists. for now, always generate new (file is never read)
        let namesUrl = URL.documentsDirectory.appending(component: url.lastPathComponent.replacing(".sf2", with: ".presetnames"))
//            print("exist: \(namesUrl.startAccessingSecurityScopedResource())")
//            print("exist: \(FileManager.default.fileExists(atPath: namesUrl.absoluteString))")
        if let names = parsePresetNames(url) {
            // useless write
//            do {
//                try SF2Parser.namesData(from: names).write(to: namesUrl)
//                print("generated new .presetnames file")
//            } catch {
//                print("write new .presetnames file failed")
//            }
            presetPicker.menu = UIMenu(options: .singleSelection, children: names.enumerated().map { (i, name) in
                let (b, p, n) = name
                return UIAction(title: "\(b):\(p) \(n)") { _ in
                    AudioEngine.presetIndexChangedNotif.post(value: UInt16(b) * 1<<8 + UInt16(p)) // bank:preset
                    UserDefaults.standard.set(UInt16(b) * 1<<8 + UInt16(p), forKey: "presetIndex_Int")
                    UserDefaults.standard.set(i, forKey: "presetMenuIndex_Int")
                }
            })
            print("updated preset picker menu")
        }
    }
    private func parsePresetNames(_ url: URL) -> SF2Parser.Names? {
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
        pbs.addTarget(self, action: #selector(sendPitchBend), for: .valueChanged)
        pbs.addTarget(self, action: #selector(elasticAnimation), for: .touchUpInside)
        pbs.addTarget(self, action: #selector(elasticAnimation), for: .touchUpOutside)
        pbs.addTarget(timer, action: #selector(timer.invalidate), for: .touchDown)
        return pbs
    }()
    @objc private func sendPitchBend() {
        AudioEngine.pitchBendChangedNotif.post(value: pitchBendSlider.value)
    }
    var timer: Timer!
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
        vs.addTarget(self, action: #selector(sendVelocity), for: .valueChanged)
        return vs
    }()
    @objc private func sendVelocity() {
        Keyboard.velocityChangedNotif.post(value: UInt8(velocitySlider.value))
        UserDefaults.standard.set(velocitySlider.value, forKey: "velocity_Float")
    }
    
}

// old keymap picker

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
    
    // TO DO: add a special segment for keymap loaded from file
    /// plan: "Open..." segment when pressed open a file select dialog, add a segment before itself and select the loaded keymap
}()
*/
