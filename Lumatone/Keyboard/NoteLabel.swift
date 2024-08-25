//
//  NoteLabel.swift
//  Lumatone
//
//  Created by SH BU on 2024/8/18.
//

import UIKit

typealias LabelMapping = (_: UInt8) -> NSAttributedString

class NoteLabel {
    static var fontText = {
        guard let font = UIFont(name: "Copperplate", size: 1) else { fatalError("Font Copperplate does not exist") }
        return font
    }()
    static var fontAccidental = {
        guard let font = UIFont(name: "Bravura", size: 1) else { fatalError("Font Bravura does not exist") }
        return font
    }()
    
    let number: LabelMapping
    let symbol: LabelMapping
    
    init(number: @escaping LabelMapping, symbol: @escaping LabelMapping) {
        self.number = number
        self.symbol = symbol
    }
    
    static func setFontSize(_ size: CGFloat) {
        fontText = fontText.withSize(size)
        fontAccidental = fontAccidental.withSize(size)
    }
    
    static func format(_ str: String, musical: Bool = false) -> NSAttributedString {
        let astr = NSMutableAttributedString(string: str, attributes: [.font : fontText])
        if str.count == 2 && musical {
            astr.addAttributes([.baselineOffset : -7], range: NSRange(location: 0, length: 1))
            astr.addAttributes([.font : fontAccidental], range: NSRange(location: 1, length: 1))
        }
        return astr
    }
}

// ♭   ♯
extension NoteLabel { // note label data
    private static let sh = "\u{E262}"
    private static let ssh = "\u{E282}"
    private static let fl = "\u{E260}"
    private static let sfl = "\u{E280}"
    
    static let emptyMapping: LabelMapping = { _ in format("") }
    
    static let noteNumberEdo = { (edo: Int) -> LabelMapping in
        { format("\(Int($0) % edo)") }
    }
    
    
    static let symbol12: LabelMapping = {
        format(
            ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"][Int($0) % 12],
            musical: true)
    }
    
    static let symbol31: LabelMapping = {
        return format(
            ["C", "C"+ssh, "C"+sh,
             "D"+fl, "D"+sfl, "D", "D"+ssh, "D"+sh,
             "E"+fl, "E"+sfl, "E", "E"+ssh,
             "F"+sfl, "F", "F"+ssh, "F"+sh,
             "G"+fl, "G"+sfl, "G", "G"+ssh, "G"+sh,
             "A"+fl, "A"+sfl, "A", "A"+ssh, "A"+sh,
             "B"+fl, "B"+sfl, "B", "B"+ssh,
             "C"+sfl][Int($0) % 31],
            musical: true)
    }
}

extension NoteLabel { // pairs
    static let empty = NoteLabel(number: emptyMapping, symbol: emptyMapping)
    
    static let edo12 = NoteLabel(number: noteNumberEdo(12), symbol: symbol12)
    
    static let edo31 = NoteLabel(number: noteNumberEdo(31), symbol: symbol31)
}
