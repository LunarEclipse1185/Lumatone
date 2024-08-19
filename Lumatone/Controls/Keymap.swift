//
//  Keymap.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/18.
//

import UIKit

typealias NoteMapping = (_: Int, _: Int) -> UInt8
typealias ColorMapping = (_: Int, _: Int) -> UIColor


class Keymap {
    let name: String
    let tuning: Int
    let note: NoteMapping
    let color: ColorMapping
    let label: NoteLabel
    
    init(_ name: String, tuning: Int, label: NoteLabel, note: @escaping NoteMapping, color: @escaping ColorMapping) {
        self.name = name
        self.tuning = tuning
        self.note = note
        self.color = color
        self.label = label
    }
    
    convenience init(_ name: String, tuning: Int, note: @escaping NoteMapping, color: @escaping ColorMapping) {
        let label: NoteLabel
        switch tuning {
        case 12:
            label = .edo12
        case 31:
            label = .edo31
        default:
            label = .empty
        }
        self.init(name, tuning: tuning, label: label, note: note, color: color)
    }
}


extension Keymap { // builtin keymaps
    
    static let builtin: [Keymap] = [.harmonicTable12, .bosanquetWilson12, .wickiHayden12, .bosanquetWilson31]
    
    
    // placeholder, to avoid using optional var
    static let empty = Keymap("", tuning: 12, label: .empty) { i, j in
        UInt8(0)
    } color: { i, j in
        .clear
    }
    
    // the classic harmonic table
    static let harmonicTable12 = Keymap("Harmonic Table", tuning: 12) { i, j in
        UInt8( 48 - 7*i + 4*j )
    } color: { i, j in
        let red = colorRGB(235, 154, 164)
        let pink = colorRGB(242, 170, 244)
        let blue = colorRGB(136, 164, 229)
        let yellow = colorRGB(227, 219, 183)
        return [blue, red, yellow, red, blue, blue, red, blue, pink, blue, red, blue][(48 - 7*i + 4*j) % 12]
    }
    
    // piano-like layout with a vertical period
    static let bosanquetWilson12 = Keymap("Bosanquet Wilson", tuning: 12) { i, j in
        UInt8( 36 - i + 2*j )
    } color: { i, j in
        let lightBlue = colorRGB(202, 219, 245)
        let darkBlue = colorRGB(97, 136, 241)
        let a = (36 - i + 2*j) % 12
        let b = a%2 == 0 ? a : 9-a
        return b < 5 ? lightBlue : darkBlue
    }
    
    // altered piano-like layout with a horizontal period
    static let wickiHayden12 = Keymap("Wicki Hayden", tuning: 12) { i, j in
        UInt8( 89 - 7*i + 2*j )
    } color: { i, j in
        let lightBlue = colorRGB(156, 190, 249)
        let darkBlue = colorRGB(114, 131, 217)
        let lightRed = colorRGB(218, 170, 158)
        let darkRed = colorRGB(187, 147, 137)
        let t = (89 - 7*i + 2*j) % 12
        return t%2==0 ? t <= 4 ? lightBlue : darkRed
                      : t <= 3 ? lightRed : darkBlue
    }
    
    // piano-like layout for 31edo
    static let bosanquetWilson31 = Keymap("Bosanquet Wilson 31", tuning: 31) { i, j in
        UInt8(clamping: 91 - 2*i + 5*j )
    } color: { i, j in
        let cy = colorRGB(142, 205, 227)
        let gr = colorRGB(128, 191, 189)
        let bl = colorRGB(139, 180, 245)
        let pr = colorRGB(167, 137, 248)
        let ne = colorRGB(158, 197, 240)
        return [ne, gr, pr, cy, bl,
                ne, gr, pr, cy, bl,
                ne, cy, pr, ne, gr,
                pr, cy, bl, ne, gr,
                pr, cy, bl, ne, gr,
                pr, cy, bl, ne, cy, pr][(91 - 2*i + 5*j) % 31]
    }
}
// two classes or (UInt8, UIColor)?

extension Keymap: CustomStringConvertible {
    var description: String { name }
}
