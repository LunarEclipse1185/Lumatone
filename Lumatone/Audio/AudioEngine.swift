//
//  AudioEngine.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/18.
//

import AVFoundation

class AudioEngine {
    // notification templates
    static let pitchBendChangedNotif = TypedNotification<Float>(name: "pitchBendChanged")
//    static let masterGainChangedNotif = TypedNotification<Float>(name: "masterGainChanged") // unused
    static let tuningChangedNotif = TypedNotification<Int>(name: "tuningChanged")
    static let presetIndexChangedNotif = TypedNotification<UInt16>(name: "presetIndexChanged")
    
    // components
    private var engine = AVAudioEngine()
    var synths: [AVAudioUnitSampler] = []
    
    // audio
    var pitchBend: Float = 0 {
        didSet { synths.forEach { $0.globalTuning = pitchBend } }
    }
    
    // setup
    init() {
        // observers
        Self.pitchBendChangedNotif.registerOnAny { [weak self] value in
            self?.pitchBend = value
        }
//        masterGainChangedNotifier = Self.masterGainChangedNotif.registerOnAny(block: setMasterGain(_:))
        Self.tuningChangedNotif.registerOnAny { [weak self] edo in
            self?.edo = edo
        }
        Self.presetIndexChangedNotif.registerOnAny { [weak self] index in
            self?.presetIndex = (UInt8(index >> 8), UInt8(index % 1<<8)) // bank, preset
//            print("preset index changed to \(self?.presetIndex)")
        }
        NotificationCenter.default.addObserver(forName: .soundfontChanged, object: nil, queue: nil) { _ in
            DispatchQueue.global().async {
                self.soundbankUrl = Self.UserDefaultsResolveSoundbankUrl()
            }
        }
    }
    
    func setupEngine() {
        setupAudioSession()
        //let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
        //engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)
        createSynth() // for 12edo
        engine.prepare()
        do {
            try engine.start()
        } catch let error as NSError {
            print("engine start error ", error.description)
        }
    }
    
    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback, options:
                                        AVAudioSession.CategoryOptions.mixWithOthers)
        } catch {
            print("couldn't set category \(error)")
            return
        }
        do {
            try audioSession.setActive(true)
        } catch {
            print("couldn't set category active \(error)")
            return
        }
    }
    
    func stopAudio() { // unused
        for synth in synths {
            AudioUnitReset(synth.audioUnit, kAudioUnitScope_Global, 0)
            synth.reset()
            engine.detach(synth)
        }
        engine.reset()
    }
    
    // instrument info
    var soundbankUrl: URL! {
        didSet {
            if let url = soundbankUrl {
                if oldValue != nil && url == oldValue { // unchanged
                    print("soundbank is set but not changed")
                    return
                }
                if !url.startAccessingSecurityScopedResource() { return }
                print("async changing soundbank to \(url.lastPathComponent), keeping preset index \(presetIndex)")
                synths.forEach { loadPresetAsync(at: presetIndex, for: $0) }
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
    var presetIndex: (UInt8, UInt8) = (UInt8(UserDefaults.standard.integer(forKey: "presetIndex_Int") >> 8),
                                       UInt8(UserDefaults.standard.integer(forKey: "presetIndex_Int") % 1<<8)) {
        didSet {
            if let url = soundbankUrl {
                if url.startAccessingSecurityScopedResource() {
                    print("async changing preset to \(presetIndex)")
                    synths.forEach { loadPresetAsync(at: presetIndex, for: $0) }
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
    
    
    // modifying engine structure
    static func UserDefaultsResolveSoundbankUrl() -> URL {
        do {
            if let data = UserDefaults.standard.object(forKey: "soundfontFileUrl_Data") as? Data { // read url data
                //print("retrieved url bookmark: \(data)")
                var stale: Bool = false
                let fileUrl = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale)
                if stale {
                    print("updating stale bookmark")
                    UserDefaults.standard.set(try fileUrl.bookmarkData(), forKey: "soundfontFileUrl_Data")
                }
                print("resolve from bookmark succeeded: \(fileUrl.lastPathComponent)")
                return fileUrl // success
            }
        } catch let error {
            // if fail to locate file, eg file moved during 2 statements
            // fallthrough
            print("caught error \(error)")
        }
        
        // all fail situation OR first time run
        guard let defaultUrl = Bundle.main.url(forResource: "YamahaGrand", withExtension: "sf2") else {
            fatalError("built-in soundfont is unavailable")
        }
        UserDefaults.standard.set(try! defaultUrl.bookmarkData(), forKey: "soundfontFileUrl_Data")
        print("first time run or file moved during code execution, using built-in soundfont")
        return defaultUrl
    }
//    static func UserDefaultsGetSoundbankUrl() -> URL {
//        var url = UserDefaults.standard.url(forKey: "soundfontFileUrl_URL")
//        print("get url: ", url?.absoluteString ?? "nil")
//        if let url2 = url {
//            if url2.startAccessingSecurityScopedResource() {
//                //print("start access")
//                if !FileManager.default.fileExists(atPath: url2.path()) {
//                    print("file from UserDefaults does not exist")
//                    url = Bundle.main.url(forResource: "YamahaGrand", withExtension: "sf2")
//                }
//                url2.stopAccessingSecurityScopedResource()
//                //print("end access")
//            }
//        } else {
//            url = Bundle.main.url(forResource: "YamahaGrand", withExtension: "sf2")
//        }
//        guard let url2 = url else { fatalError("built-in soundfont not available") }
//        return url2
//    }
    
    private func createSynth(withTuning cents: Float = 0) {
        let newSynth = AVAudioUnitSampler()
        newSynth.globalTuning = cents
        synths.append(newSynth)
        
        engine.attach(newSynth)
        engine.connect(newSynth, to: engine.mainMixerNode, format: nil)
        
        DispatchQueue.global().async {
            self.loadPresetAsync(at: self.presetIndex, for: newSynth)
        }
    }
    
    private func loadPresetAsync(at index: (UInt8, UInt8), for synth: AVAudioUnitSampler) { // recommend to call async'ly
        DispatchQueue.global().async {
            let (bank, preset) = index
            if self.soundbankUrl == nil {
                self.soundbankUrl = Self.UserDefaultsResolveSoundbankUrl() // costly
            }
            do {
                try synth.loadSoundBankInstrument(
                    at: self.soundbankUrl,
                    program: preset,
                    bankMSB: UInt8(bank < 128 ? kAUSampler_DefaultMelodicBankMSB : kAUSampler_DefaultPercussionBankMSB),
                    bankLSB: bank < 128 ? bank : 0)
            } catch let error as NSError {
                switch error.code {
                case -43: // not found
                    print("SF2 file not found")
                case -54: // permission error for SF2 file
                    print("permission error for SF2 file")
                default:
                    break
                }
            }
        }
    }
    
    // midi api
    
    // multiple synths method
    private var edo: Int = 12 {
        didSet {
            guard edo > 0 else {
                edo = oldValue
                return
            }
            
            if edo == 12 {
                synths[0].globalTuning = 0.0
                return
            }
            
            for (note, synth) in synths.enumerated() {
                synth.globalTuning = getFracNote(note) * 100
            }
            while synths.count < edo {
                createSynth(withTuning: getFracNote(synths.count) * 100)
            }
        }
    }
    private func getFracNote(_ note: Int) -> Float { // in cents
        return Float(note)/Float(edo)*12.0 - round( Float(note)/Float(edo)*12.0 )
    }
    private func getReprNote(_ note: UInt8) -> UInt8 { // represent note in 12edo
        return UInt8(round( Double(note)/Double(edo)*12.0 ))
    }
    
    func startNote(_ note: UInt8, withVelocity velocity: UInt8) {
        if edo == 12 {
            synths[0].startNote(note, withVelocity: velocity, onChannel: 0)
        } else {
            synths[Int(note)%edo].startNote(getReprNote(note), withVelocity: velocity, onChannel: 0)
        }
    }
    
    func stopNote(_ note: UInt8) {
        if edo == 12 {
            synths[0].stopNote(note, onChannel: 0)
        } else {
            synths[Int(note)%edo].stopNote(getReprNote(note), onChannel: 0)
        }
    }
    
    // failed attempt: MTS sys ex event
    
    /*
    public func changeTuning(edo: Int) {
        guard edo > 0 else { return }
        self.edo = edo
        
        
        // failed method: MTS sysEx evennt
        
        var data = Data()
        let outputDeviceID: UInt8 = 0
        let targetProgram: UInt8 = 0
        data.append(contentsOf: [0xF0, 0x7F, outputDeviceID, 0x08, 0x02, targetProgram, 128])
        for note in 0...127 {
            data.append(contentsOf: [UInt8(note)])
            data.append(contentsOf: encodeTuningData(fromSemitones: Double(note)/Double(edo)*12.0))
            //print(note, encodeTuningData(fromSemitones: Double(note)/Double(edo)*12.0))
        }
        data.append(contentsOf: [0xF7])
        for id: UInt8 in 0...127 {
            data[2] = id
            synth?.sendMIDISysExEvent(data)
        }
    }
    
    private func encodeTuningData(fromSemitones semi: Double) -> [UInt8] {
        let inte = Int(semi)
        guard inte >= 0 && inte <= 127 else { return [] }
        let fracHigh = Int(semi * 128) - inte * 128
        let fracLow = Int(semi * 128 * 128) - inte * 128 * 128 - fracHigh * 128
        return [UInt8(inte), UInt8(fracHigh), UInt8(fracLow)]
    }
    */
    
    // failed attempt: multiple channels
    
    //private var chanMap: [UInt8 : UInt8] = [:] // chan : note
    /*
    
    public func changeTuning(edo: Int) {
        guard edo > 0 else { return }
        self.edo = edo
    }
    
    private func getRepr(_ note: UInt8) -> UInt8 { // represent note in 12edo
        return UInt8(round( Double(note)/Double(edo)*12.0 ))
    }
    
    private func getFrac(_ note: UInt8) -> Double {
        return Double(note)/Double(edo)*12.0 - round( Double(note)/Double(edo)*12.0 )
    }
    
    private func map(_ x: Double, _ fromL: Double, _ fromR: Double, _ toL: Double, _ toR: Double) -> Double {
        //guard fromR - fromL != 0 else { return Double.nan }
        return (x - fromL) / (fromR - fromL) * (toR - toL) + toL
    }

    public func startNote(_ note: UInt8, withVelocity velocity: UInt8) {
        // get first empty channel
        var chan: UInt8 = 0
        while chanMap[chan] != nil { chan += 1 }
        if chan == 16 { return } // 17th note dropped
        chanMap[chan] = note
        
        synth?.startNote(getRepr(note), withVelocity: velocity, onChannel: chan)
        synth?.sendPitchBend(UInt16(map(getFrac(note), -2, 2, 0, 16384)), onChannel: chan)
        print("Start Note: ", note, " represented by ", getRepr(note), " on channel ", chan)
    }
    
    public func stopNote(_ note: UInt8) {
        // search for note
        var chan: UInt8 = 0
        while chanMap[chan] != note && chan < 16 { chan += 1 }
        if chan == 16 { return } // note not playing
        chanMap[chan] = nil
        
        synth?.stopNote(getRepr(note), onChannel: chan)
        print("Stop Note: ", note, " represented by ", getRepr(note), " on channel ", chan)
    }
    */
}

/*
 AVAudioSampler has member:
  overallGain
  stereoPan
  globalTuning
  stopNote(note, onChannel: 0)
  startNote(note, withVelocity: velocity, onChannel: 0)
  sendPressure(forKey: note, withValue: pressure, onChannel: 0)
  sendController(controller, withValue: value, onChannel: 0)
  sendPitchBend(value, onChannel: 0)
  sendPressure(pressure, onChannel: 0)
  sendProgramChange(program, onChannel: 0)
 
 func setPitchBendRange(value: UInt8) {
   guard value < 25 else { return }
   sendMIDIEvent(0xB0, data1: 101, data2: 0)
   sendMIDIEvent(0xB0, data1: 100, data2: 0)
   sendMIDIEvent(0xB0, data1: 6, data2: value)
   sendMIDIEvent(0xB0, data1: 38, data2: 0)
 }
 
 func stopAllNotes() {
   AudioUnitReset(self.audioUnit, kAudioUnitScope_Global, 0)
   reset()
 }
 */
