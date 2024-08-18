//
//  Keyboard.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/18.
//

import UIKit

class Keyboard: UIView {
    
    // for now the keyboard layout is hardcoded
    public static let coshori: CGFloat = cos(-0.2810349)
    public static let sinhori: CGFloat = sin(-0.2810349)
    public static let cosvert: CGFloat = cos(+1.8133602)
    public static let sinvert: CGFloat = sin(+1.8133602)
    
    public static let LayoutRowLengths: [Int] =
    [2, 5, 8, 11, 14, 17, 20, 23, 26, 28, 26, 23, 20, 17, 14, 11, 8, 5, 2]
    public static let LayoutRowOffs: [Int] =
    [0, 1, 1, 2, 2, 3, 3, 4, 4, 6, 9, 13, 16, 20, 23, 27, 30, 34, 37]
    
    // components
    private var audioEngine: AudioEngine
    private var keymap: Keymap
    
    private var keys: [[Key]]
    private var lockButton = LockButton()
    private var contentWidth: CGFloat = 0 // to be changed to contentSize: CGRect
    
    
    required init(coder: NSCoder) { fatalError() }
    
    init(_ engine: AudioEngine) {
        self.audioEngine = engine
        
        keymap = .empty // keymap initialized from KeymapPicker call
        // TODO: caused `no factory` warning
        
        keys = []
        for i in 0 ..< Keyboard.LayoutRowLengths.count {
            var row: [Key] = []
            for _ in 0 ..< Keyboard.LayoutRowLengths[i] {
                row.append(Key())
            }
            keys.append(row)
        }
        
        //        keys = [[Key(synth: audioEngine.synth!)]]
        
        
        super.init(frame: .zero)
        
        self.backgroundColor = #colorLiteral(red: 0.8770987988, green: 0.8770987988, blue: 0.8770987988, alpha: 1)
        self.bounds.origin.x = 600 // TODO: ugly
        self.isMultipleTouchEnabled = true
        
        keys.forEach { row in
            row.forEach { key in
                addSubview(key)
            }
        }
        addSubview(lockButton)
        
        lockButton.keyboard = self
    }
    
    func changeKeymap(_ keymap: Keymap) {
        stopAllNotes()
        self.keymap = keymap
        for i in 0 ..< keys.count {
            for j in 0 ..< keys[i].count {
                let note = keymap.note(i, j + Keyboard.LayoutRowOffs[i])
                let color = keymap.color(i, j + Keyboard.LayoutRowOffs[i])
                keys[i][j].assign(note: note, color: color)
            }
        }
        audioEngine.changeTuning(edo: keymap.tuning)
    }
    
    func stopAllNotes() {
        for (_, keys) in touchedKeys {
            for key in keys {
                audioEngine.stopNote(key.note)
                key.deactivate()
            }
        }
    }
    
    
    // rendering and user interaction
    
    var scale: CGFloat = 1.0
    
    override func layoutSubviews() {
        lockButton.frame.origin = CGPointMake(20 + self.bounds.origin.x, self.frame.height-70)
        
        let gridUnit = self.frame.height / 9.0
        contentWidth = 34.186 * gridUnit
        scale = gridUnit / 60 // smaller denominator, tighter spacing
        for (i, row) in keys.enumerated() {
            for (j, key) in row.enumerated() {
                // positioning
                var centerX = gridUnit
                centerX += CGFloat(i) * Keyboard.cosvert * gridUnit
                centerX += CGFloat(j + Keyboard.LayoutRowOffs[i]) * Keyboard.coshori * gridUnit
                
                var centerY = 0.5 * self.frame.height - 3.4 * gridUnit
                centerY += CGFloat(i) * Keyboard.sinvert * gridUnit
                centerY += CGFloat(j + Keyboard.LayoutRowOffs[i]) * Keyboard.sinhori * gridUnit
                
                // scaling
                key.scale = scale
                
                key.frame.origin = CGPointMake(centerX, centerY)
            }
        }
    }
    
    
    private let touchRadius: CGFloat = 45
    private var touchedKeys: [UITouch: Set<Key>] = [:]
    // this model doesn't produce desired (natural) behavior when sequence
    // 'touch1down touch2down touch1up touch2up' all target some one key
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO: only search visible keys
        if !lockButton.locked { return }
        for touch in touches {
            touchedKeys[touch] = Set<Key>()
            for row in keys {
                for key in row {
                    //if !CGRectMake(key.frame.origin.x - touchRadius, key.frame.origin.y - touchRadius, touchRadius*2, touchRadius*2).contains(touch.location(in: self)) { continue }
                    if CGPointDistanceSquared(touch.location(in: self), key.frame.origin) > touchRadius*touchRadius { continue }
                    key.activate(touch, with: event)
                    audioEngine.startNote(key.note, withVelocity: Globals.globalVelocity)
                    touchedKeys[touch]?.insert(key)
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !lockButton.locked { return }
        for touch in touches {
            guard let set = touchedKeys[touch] else { continue }
            for key in set {
                key.deactivate()
                audioEngine.stopNote(key.note)
            }
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
        bounds.origin.x = max(0, bounds.origin.x)
        bounds.origin.x = min(contentWidth - frame.width, bounds.origin.x)
        // add inertia
    }
    
    
}
