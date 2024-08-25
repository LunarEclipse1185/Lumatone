//
//  SF2Parser.swift
//  Lumatone
//
//  Created by SH BU on 2024/8/25.
//

import Foundation

class SF2Parser {
    enum Option: Int { // conform to Equatable
        case parsePresetNames
    }
    
    typealias Names = [(bank: UInt8, preset: UInt8, name: String)]
    
    var data: Data
    var options: [Option]!
    var namesParsed: Names = []
    
    var conformToSpec = true
    var output = "" { didSet { output += "\n" } }
    var log = "" { didSet { log += "\n" } }
    var error = "" { didSet { error += "\n" } }
    
    init(data: Data) {
        self.data = data
    }
    
    static func sortNames(_ names: Names) -> Names {
        return names.sorted { l, r in
            //(l.bank != r.bank) ? (l.bank < r.bank) : (l.preset < r.preset)
//            r.bank == 128 ? (l.preset < r.preset)
            if l.bank == 128 && r.bank == 128 {
                return l.preset < r.preset
            }
            if (l.bank == 128) != (r.bank == 128) {
                return r.bank == 128
            }
            return (l.preset != r.preset) ? (l.preset < r.preset) : (l.bank < r.bank)
        }
    }
    
    static func namesData(from names: Names) -> Data {
        var data = Data()
        for (b, p, n) in names {
            data.append(contentsOf: [b, p])
            data.append(contentsOf: n.cString(using: .ascii)!.map { UInt8($0) })
            data.append(contentsOf: [UInt8](repeating: 0, count: 20 - n.count - 1))
        }
        return data
    }
    
    static func namesObject(from data: Data) -> Names {
        var names: Names = []
        var index = data.startIndex
        while index < data.endIndex { // endIndex == count and is outside bound
            names += [(bank: data[index], preset: data[index + 1], name: String(cString: data[index+2..<index+22] + [0]))]
            index += 22
        }
        return names
    }
    
    func parse(options: [Option]) -> Bool {
        self.options = options
        
        log += "Length of file:      \(data.count.formatted())"
        if options.contains(.parsePresetNames) {
            // listing preset names
//            let presetListPath = ["RIFF", "LIST"]
            log += "entering struct:     \(readStr(count: 4))" // RIFF
            log += "    with size:       \(readInt(count: 4))"
            log += "    with name:       \(readStr(count: 4))" // sfbk
            
            log += "skipping struct:     \(readStr(count: 4))"
            let size1 = readInt(count: 4)
            log += "    with size:       \(size1)"
            data = data.dropFirst(Int(size1))
            
            log += "skipping struct:     \(readStr(count: 4))"
            let size2 = readInt(count: 4)
            log += "    with size:       \(size2)"
            data = data.dropFirst(Int(size2))
            
            log += "entering struct:     \(readStr(count: 4))" // LIST
            let listSize = readInt(count: 4)
            log += "    with size:       \(listSize)"
            log += "    with name:       \(readStr(count: 4))" // pdta
            
            let name = readStr(count: 4)
            log += "entering struct:     \(name)" // phdr
            let phdrSize = readInt(count: 4)
            log += "    with size:       \(phdrSize)"
            
            var bytesRead: UInt32 = 0
            while bytesRead < phdrSize {
                let presetName = readStr(count: 20)
                log += "read preset name:    \(presetName)"
                let presetIndex = readInt(count: 2)
                log += "read preset index:   \(presetIndex)"
                let bankIndex = readInt(count: 2)
                log += "read bank index:     \(bankIndex)"
                
                output += "\(bankIndex):\(presetIndex) \(presetName)"
                namesParsed += [(bank: UInt8(bankIndex), preset: UInt8(presetIndex), name: presetName)]
                
                data = data.dropFirst(38 - 24)
                bytesRead += 38
            }
            
            data = data.dropFirst(Int(listSize - bytesRead))
            log += data.count == 0 ? "all bytes read" : "NOT ALL BYTES READ"
            
            namesParsed.removeLast()
        }
        
        return conformToSpec
    }
    
    
    // read given amount of bytes as some type
    
    private func readBytes(count: Int) -> [UInt8] {
        guard count <= data.count else {
            fatalError("reading bytes \(count) exceeded data length \(data.count)")
        }
        var bytes = [UInt8](repeating: 0, count: count)
        data.copyBytes(to: &bytes, count: count)
        data = data.dropFirst(count)
        return bytes
    }
    
    private func readStr(count: Int) -> String {
        return String(cString: readBytes(count: count) + [0])
    }
    
    private func readInt(count: Int) -> UInt32 {
        guard count > 0 && count <= 4 else {
            fatalError("cannot read int of size \(count)")
        }
        let bytes = readBytes(count: count)
        return bytes.enumerated().map { UInt32($1) * 1 << (8 * $0) } .reduce(UInt32(0), +)
    }
}


// class SF2Riff represent file structure
// checks:
// RIFF size matches file size
// all lower level sizes sum up to higher level size
// chunks name order
// notice: padding byte

// a better positioning method:
// pass subData between functions (only the ckData part of the chunk)
// test if `Data.Index` is shared between whole Data and subData
