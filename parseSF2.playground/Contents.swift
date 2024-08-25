
import AppKit
import PlaygroundSupport

let view = View(frame: CGRectMake(0, 0, 300, 150))
PlaygroundPage.current.liveView = view

class View: NSView {
    
    required init?(coder: NSCoder) { fatalError() }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.layer?.backgroundColor = .black
        
        addSubview(button)
        
        button.frame = CGRectMake(50, 50, 200, 50)
        
        selectFile()
    }
    
    lazy var button = {
        let button = NSButton(title: "Choose File", target: self, action: #selector(selectFile))
        return button
    }()
    @objc func selectFile() {
        openPanel.begin { _ in
            if self.openPanel.urls.count == 0 { return }
            self.recievedFileUrl(self.openPanel.urls[0])
        }
    }
    lazy var openPanel = {
        let panel = NSOpenPanel()
        //panel.title = "title"
        //panel.prompt = "prompt"
        //panel.message = "message"
        return panel
    }()
    
    // parse
    func recievedFileUrl(_ url: URL) {
        print("recieved url: \(url)")
        if url.startAccessingSecurityScopedResource() {
            if let data = try? Data(contentsOf: url) {
                parseSF2(data)
            }
            url.stopAccessingSecurityScopedResource()
        } else {
            print("access denied")
        }
    }
    
    func parseSF2(_ data: Data) {
        let parser = Parser(data: data)
        let status = parser.parse(options: [.parsePresetNames])
        
//        let printLog = false
//        print("[output]\n\(parser.output)")
//        if printLog {
//            print("[log]\n\(parser.log)")
//        }
//        if !status {
//            print("[error]\n\(parser.error)")
//        }
        
        parser.sortNames()
        
        for (b, p, n) in parser.presetNames {
            print("\(b):\(p) \(n)")
        }
    }
}

class Parser {
    enum Option: Int { // conform to Equatable
        case parsePresetNames
    }
    
    var data: Data
    var options: [Option]!
    var presetNames: [(bank: UInt8, preset: UInt8, name: String)] = []
    
    var conformToSpec = true
    var output = "" { didSet { output += "\n" } }
    var log = "" { didSet { log += "\n" } }
    var error = "" { didSet { error += "\n" } }
    
    init(data: Data) {
        self.data = data
    }
    
    func sortNames() {
        presetNames.sort { l, r in
            (l.bank != r.bank) ? (l.bank < r.bank) : (l.preset < r.preset)
        }
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
                presetNames += [(bank: UInt8(bankIndex), preset: UInt8(presetIndex), name: presetName)]
                data = data.dropFirst(38 - 24)
                bytesRead += 38
            }
            
            data = data.dropFirst(Int(listSize - bytesRead))
            log += data.count == 0 ? "all bytes read" : "NOT ALL BYTES READ"
            
            presetNames.removeLast()
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
