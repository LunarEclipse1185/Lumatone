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
    
    // observers
    private var keymapChangedNotifier: NotificationObserver?
    private var velocityChangedNotifier: NotificationObserver?
    
    // components
    private var audioEngine: AudioEngine
    
    private var lockButton = LockButton()
    
    private var keys: [[Key]]
    private var keymap: Keymap {
        didSet {
            stopAllNotes()
            for i in 0 ..< keys.count { for j in 0 ..< keys[i].count {
                let note = keymap.note(i, j + Keyboard.LayoutRowOffs[i])
                let color = keymap.color(i, j + Keyboard.LayoutRowOffs[i])
                keys[i][j].assign(note: note, color: color, labelMapping: keymap.label.symbol) // add configuration
            }}
        }
    }
    
    
    required init(coder: NSCoder) { fatalError() }
    
    init(_ engine: AudioEngine) {
        self.audioEngine = engine
        
        keys = []
        for i in 0 ..< Keyboard.LayoutRowLengths.count {
            var row: [Key] = []
            for _ in 0 ..< Keyboard.LayoutRowLengths[i] {
                row.append(Key())
            }
            keys.append(row)
        }
        
        keymap = .empty // triggers key.assign
        
        
        super.init(frame: .zero)
        
        self.backgroundColor = #colorLiteral(red: 0.8770987988, green: 0.8770987988, blue: 0.8770987988, alpha: 1)
        //self.backgroundColor = #colorLiteral(red: 0.6645953655, green: 0.6645954251, blue: 0.6645953655, alpha: 1)
        bounds.origin.x = -1 // set signal for initializing
        self.isMultipleTouchEnabled = true
        
        keys.forEach { $0.forEach { addSubview($0) } }
        addSubview(lockButton)
        
        lockButton.keyboard = self
        
        // add observers
        keymapChangedNotifier = Self.keymapChangedNotif.registerOnAny { [weak self] keymap in
            self?.keymap = keymap
        }
        velocityChangedNotifier = Self.velocityChangedNotif.registerOnAny { [weak self] vel in
            self?.velocity = vel
        }
    }
    
    func stopAllNotes() {
        touchedKeys.forEach { $1.forEach { releaseKey($0) } }
    }
    
    
    // rendering and user interaction
    
    private var contentWidth: CGFloat = 0 // change to contentSize: CGRect if support zooming
    // below two meant to be changed by instance owner
    var scale: CGFloat = 1.0 {
        didSet { // adjust keyb position so that the middle point stays still
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
    
    
    private let touchRadius: CGFloat = 45 // unscaled
    private var touchedKeys: [UITouch: Set<Key>] = [:]
    // this model doesn't produce desired (natural) behavior when sequence
    // 'touch1down touch2down touch1up touch2up' all target some one key
    private var velocity: UInt8 = 0 // value here doesnt matter
    
    // `multiPressEnabled` meant to be set by instance owner
    var multiPressEnabled: Bool = true
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO: only search visible keys
        if !lockButton.locked { return }
        for touch in touches {
            touchedKeys[touch] = Set<Key>() // create empty set
            var minDistKey: Key!
            var minDistSq = CGFloat.infinity
            for row in keys { for key in row {
                let distSq = CGPointDistanceSquared(touch.location(in: self), key.frame.origin)
                if distSq > touchRadius*touchRadius*scale*scale { continue }
                touchedKeys[touch]?.insert(key)
                if !multiPressEnabled && distSq < minDistSq {
                    minDistSq = distSq
                    minDistKey = key
                }
            }}
            if multiPressEnabled {
                touchedKeys[touch]?.forEach { pressKey($0) }
            } else {
                pressKey(minDistKey)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !lockButton.locked { return }
        for touch in touches {
            guard let set = touchedKeys[touch] else { continue }
            set.forEach { releaseKey($0) }
            touchedKeys.removeValue(forKey: touch)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesEnded(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO: add dragging play mode
        if lockButton.locked { return }
        bounds.origin.x -= touches.first!.location(in: self).x - touches.first!.previousLocation(in: self).x
        bounds.origin.x = clamp(bounds.origin.x, 0, contentWidth - frame.width)
        // add inertia
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
