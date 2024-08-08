//
//  AudioEngine.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/18.
//

import AVFoundation

class AudioEngine {
    
    private var engine = AVAudioEngine()
    public var synths: [AVAudioUnitSampler] = []
    
    public func setupEngine() {
        //synth = AVAudioUnitSampler()
        
        //let synth = self.synth!
        
        //let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
        //engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)
        createSynth() // for 12edo
        engine.prepare()

        do {
            try engine.start()
        } catch let error as NSError {
            print("engine start error ", error.description)
        }
        
        setupAudioSession()
        
    }
    
    private func createSynth(withTuning cents: Float = 0) {
        let synth = AVAudioUnitSampler()
        synth.globalTuning = cents
        synths.append(synth)
        
        engine.attach(synth)
        engine.connect(synth, to: engine.mainMixerNode, format: nil)
        
        loadInstrument(synth)
    }
    
    private func loadInstrument(_ synth: AVAudioUnitSampler, presetIndex: UInt8 = Globals.presetIndex) {
        guard let bankURL = Bundle.main.url(forResource: "YamahaGrand", withExtension: "sf2")
            else { fatalError("load soundfont failed") }
        
        do {
            try synth.loadSoundBankInstrument(
                at: bankURL,
                program: presetIndex,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB))
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
    
    public func loadInstrument(presetIndex: UInt8 = Globals.presetIndex) {
        for synth in synths {
            loadInstrument(synth, presetIndex: presetIndex)
        }
    }
    
    public func stopAudio() { // never called
        for synth in synths {
            AudioUnitReset(synth.audioUnit, kAudioUnitScope_Global, 0)
            synth.reset()
            engine.detach(synth)
        }
        engine.reset()
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
    
    // midi api
    
    private var edo = 12
    
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
    
    // multiple synths method
    
    private func getFrac(_ note: Int) -> Float { // in cents
        return Float(note)/Float(edo)*12.0 - round( Float(note)/Float(edo)*12.0 )
    }
    
    private func getRepr(_ note: UInt8) -> UInt8 { // represent note in 12edo
        return UInt8(round( Double(note)/Double(edo)*12.0 ))
    }
    
    public func changeTuning(edo: Int) {
        guard edo > 0 else { return }
        self.edo = edo
        
        if edo == 12 {
            synths[0].globalTuning = 0.0
            return
        }
        
        for (note, synth) in synths.enumerated() {
            synth.globalTuning = getFrac(note) * 100
        }
        while synths.count < edo {
            createSynth(withTuning: getFrac(synths.count) * 100)
        }
    }
    
    public func startNote(_ note: UInt8, withVelocity velocity: UInt8) {
        if edo == 12 {
            synths[0].startNote(note, withVelocity: velocity, onChannel: 0)
        } else {
            synths[Int(note)%edo].startNote(getRepr(note), withVelocity: velocity, onChannel: 0)
        }
    }
    
    public func stopNote(_ note: UInt8) {
        if edo == 12 {
            synths[0].stopNote(note, onChannel: 0)
        } else {
            synths[Int(note)%edo].stopNote(getRepr(note), onChannel: 0)
        }
    }
    
    
    @inlinable
    public func setPitchBend(_ value: Float) {
        for synth in synths {
            synth.globalTuning = value
        }
    }
    
    @inlinable
    public func setMasterGain(_ value: Float) { // never called
        for synth in synths {
            synth.overallGain = value
        }
    }
    
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
