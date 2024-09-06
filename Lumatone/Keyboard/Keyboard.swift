//
//  Keyboard.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/18.
//

import UIKit

class Keyboard: UIView {
    
    // hardcoded layout
    public static let coshori: CGFloat = cos(-0.2810349)
    public static let sinhori: CGFloat = sin(-0.2810349)
    public static let cosvert: CGFloat = cos(+1.8133602)
    public static let sinvert: CGFloat = sin(+1.8133602)
    
    public static let LayoutRowLengths: [Int] =
    [2, 5, 8, 11, 14, 17, 20, 23, 26, 28, 26, 23, 20, 17, 14, 11, 8, 5, 2]
    public static let LayoutRowOffs: [Int] =
    [0, 1, 1, 2, 2, 3, 3, 4, 4, 6, 9, 13, 16, 20, 23, 27, 30, 34, 37]
    
    // notifications
    static let keymapChangedNotif = TypedNotification<Keymap>(name: "keymapChanged")
    static let velocityChangedNotif = TypedNotification<UInt8>(name: "velocityChanged")
    static let multiPressChangedNotif = TypedNotification<Bool>(name: "multiPressChanged")
    static let draggingChangedNotif = TypedNotification<Bool>(name: "draggingChanged")
    static let lockButtonChangedNotif = TypedNotification<Bool>(name: "lockButtonChanged")
    static let keyLabelStyleChangedNotif = TypedNotification<Int>(name: "keyLabelStyleChanged")
    
    // components
    private var audioEngine: AudioEngine
    
    private var lockButton = LockButton()
    private var lockButtonDisabled = UserDefaults.standard.bool(forKey: "lockButtonDisabled_Bool") {
        didSet {
            lockButton.isHidden = lockButtonDisabled
            if lockButtonDisabled { lockButton.locked = true } // set to natural state
        }
    }
    
    private var keys: [[Key]] = []
    private var keymap: Keymap = Keymap.searchBuiltinKeymap(UserDefaults.standard.string(forKey: "keymapName_String") ?? "Harmonic Table") ?? .empty {
        didSet {
//            print("didset keymap")
            let label = Self.labelType(of: keymap, id: UserDefaults.standard.integer(forKey: "keyLabelStyle_Int"))
            if keymap === oldValue { return }
            stopAllNotes()
            for i in 0 ..< keys.count { for j in 0 ..< keys[i].count {
                let note = keymap.note(i, j + Keyboard.LayoutRowOffs[i])
                let color = keymap.color(i, j + Keyboard.LayoutRowOffs[i])
                keys[i][j].assign(note: note, color: color, labelMapping: label)
            }}
        }
    }
    
    
    required init(coder: NSCoder) { fatalError() }
    
    init(_ engine: AudioEngine) {
        audioEngine = engine
        
        let label = Self.labelType(of: keymap, id: UserDefaults.standard.integer(forKey: "keyLabelStyle_Int"))
        for i in 0 ..< Keyboard.LayoutRowLengths.count {
            var row: [Key] = []
            for j in 0 ..< Keyboard.LayoutRowLengths[i] {
                row.append(Key(note: keymap.note(i, j + Keyboard.LayoutRowOffs[i]),
                               color: keymap.color(i, j + Keyboard.LayoutRowOffs[i]),
                               labelMapping: label))
            }
            keys.append(row)
        }
        
        
        super.init(frame: .zero)
        
        // appearance
        self.backgroundColor = #colorLiteral(red: 0.8770987988, green: 0.8770987988, blue: 0.8770987988, alpha: 1)
        self.isMultipleTouchEnabled = true
        bounds.origin.x = UserDefaults.standard.object(forKey: "keyboardPositionX_Double") as? Double
                          ?? -1 // set signal for initializing
        
        
        lockButton.keyboard = self
        lockButton.isHidden = lockButtonDisabled // ugly, separated
        
        keys.forEach { $0.forEach { addSubview($0) } }
        addSubview(lockButton)
        
        // add observers
        Self.keymapChangedNotif.registerOnAny { keymap in
            self.keymap = keymap
        }
        Self.velocityChangedNotif.registerOnAny { vel in
            self.velocity = vel
        }
        Self.multiPressChangedNotif.registerOnAny { value in
            self.multiPressEnabled = value
        }
        Self.draggingChangedNotif.registerOnAny { value in
            self.draggingEnabled = value
        }
        Self.lockButtonChangedNotif.registerOnAny { value in
            self.lockButtonDisabled = value
        }
        Self.keyLabelStyleChangedNotif.registerOnAny { index in
            self.keys.forEach { $0.forEach { $0.assign(labelMapping: Self.labelType(of: self.keymap, id: index)) } }
        }
    }
    static func labelType(of keymap: Keymap, id: Int) -> LabelMapping {
        switch id {
            case 0: // Symbol
                return keymap.label.symbol
            case 1: // Numeral
                return keymap.label.number
            case 2: // None
                return NoteLabel.emptyMapping
            default:
                fatalError("Unregistered value sent to keyLabelStyleChanged notification")
        }
    }
    
    func stopAllNotes() {
        touchedKeys.forEach { $1.forEach { releaseKey($0) } }
    }
    
    
    // rendering
    private var contentWidth: CGFloat = 0 // change to contentSize: CGRect if support zooming
    // below two meant to be changed by instance owner
    var scale: CGFloat! {
        didSet { // adjust keyb position so that the middle point stays still
            if oldValue == nil { return } // when setting init value
            bounds.origin.x = clamp(-frame.width / 2 + (bounds.origin.x + frame.width / 2) * scale / oldValue, 0, contentWidth - frame.width)
        }
    }
    var padding: CGFloat = 0.0 // in gridUnit
    
    override func layoutSubviews() {
        let gridUnit = frame.height / (9.0 + 2 * padding)
        
        contentWidth = 34.186 * gridUnit
        if bounds.origin.x == -1 { // initial position middle
            bounds.origin.x = contentWidth / 2 - frame.width / 2
        }
        scale = gridUnit / 60 // smaller denominator, tighter spacing, formally 67.5
        lockButton.frame.origin = CGPointMake(20 + bounds.origin.x, frame.height-70)
        
        
        for (i, row) in keys.enumerated() { for (j, key) in row.enumerated() {
            // positioning
            var centerX = gridUnit
            centerX += CGFloat(i) * Keyboard.cosvert * gridUnit
            centerX += CGFloat(j + Keyboard.LayoutRowOffs[i]) * Keyboard.coshori * gridUnit
            
            var centerY = 0.5 * frame.height - 3.4 * gridUnit
            centerY += CGFloat(i) * Keyboard.sinvert * gridUnit
            centerY += CGFloat(j + Keyboard.LayoutRowOffs[i]) * Keyboard.sinhori * gridUnit
            
            // scaling and positioning
            key.scale = scale
            key.frame.origin = CGPointMake(centerX, centerY)
        }}
    }
    
    
    // user interaction
    private let touchRadius: CGFloat = 45 // unscaled
    private var touchedKeys: [UITouch: Set<Key>] = [:]
    // this model doesn't produce desired (natural) behavior when sequence
    // 'touch1down touch2down touch1up touch2up' all target some one key
    private var velocity: UInt8 = UserDefaults.standard.object(forKey: "velocity_Float") as? UInt8 ?? 64 // value here doesnt matter
    
    // `multiPressEnabled` meant to be set by instance owner
    var multiPressEnabled: Bool = UserDefaults.standard.bool(forKey: "multiPress_Bool")
    var draggingEnabled: Bool = UserDefaults.standard.bool(forKey: "draggingEnabled_Bool")
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !lockButton.locked { return }
        for touch in touches {
            let set = getKeysAtLocation(touch.location(in: self))
            if set.isEmpty { continue }
            set.forEach { key in
                for (_, set) in touchedKeys {
//                    if otherTouch === touch { continue }
                    if set.contains(key) { return }
                }
                pressKey(key)
            }
            touchedKeys[touch] = set
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !lockButton.locked { return }
        for touch in touches {
            guard let set = touchedKeys[touch] else { continue }
            set.forEach { key in
                for (otherTouch, set) in touchedKeys {
                    if otherTouch === touch { continue }
                    if set.contains(key) { return }
                }
                releaseKey(key)
            }
            touchedKeys.removeValue(forKey: touch)
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesEnded(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // key dragging
        if draggingEnabled && (lockButtonDisabled || lockButton.locked) {
            for touch in touches {
                let oldSet = touchedKeys[touch]
                let newSet = getKeysAtLocation(touch.location(in: self))
                oldSet?.forEach { key in
                    for (otherTouch, set) in touchedKeys {
                        if otherTouch === touch { continue }
                        if set.contains(key) { return }
                    }
                    if newSet.contains(key) { return }
                    releaseKey(key)
                }
                newSet.forEach { key in
                    for (_, set) in touchedKeys {
                        if set.contains(key) { return }
                    }
                    pressKey(key)
                }
                if newSet.isEmpty {
                    touchedKeys.removeValue(forKey: touch)
                } else {
                    touchedKeys[touch] = newSet
                }
            }
        }
        
        // keyboard panning
        if !lockButtonDisabled && lockButton.locked { return }
        if !lockButtonDisabled || touchedKeys.isEmpty {
            bounds.origin.x -= touches.first!.location(in: self).x - touches.first!.previousLocation(in: self).x
            bounds.origin.x = clamp(bounds.origin.x, 0, contentWidth - frame.width)
            UserDefaults.standard.set(bounds.origin.x, forKey: "keyboardPositionX_Double")
        }
        // TODO: add inertia
        // TODO: when multiple fingers panning, the speed is summed
    }
    
    private func getKeysAtLocation(_ location: CGPoint) -> Set<Key> {
        var set = Set<Key>()
        var minDistSq = CGFloat.infinity
        
        for row in keys { for key in row {
            let distSq = CGPointDistanceSquared(location, key.frame.origin)
            if distSq > touchRadius*touchRadius*scale*scale { continue }
            if multiPressEnabled {
                set.insert(key)
            } else if distSq < minDistSq {
                minDistSq = distSq
                set.removeAll()
                set.insert(key)
            }
        }}
        
        return set
    }
    
    private func pressKey(_ key: Key) {
        key.pressed = true
        audioEngine.startNote(key.note, withVelocity: velocity)
    }
    private func releaseKey(_ key: Key) {
        key.pressed = false
        audioEngine.stopNote(key.note)
    }
    
}
