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
    
    init(_ name: String, tuning: Int, note: @escaping NoteMapping, color: @escaping ColorMapping) {
        self.name = name
        self.tuning = tuning
        self.note = note
        self.color = color
    }
}

extension Keymap {
    
    static let builtin: [Keymap] = [.harmonicTable12, .bosanquetWilson12, .wickiHayden12, .bosanquetWilson31]
    
    
    // placeholder, to avoid using optional var
    static let empty = Keymap("", tuning: 12) { i, j in
        UInt8(0)
    } color: { i, j in
        return .clear
    }
    
    // the classic harmonic table
    static let harmonicTable12 = Keymap("Harmonic Table", tuning: 12) { i, j in
        UInt8( 48 - 7*i + 4*j )
    } color: { i, j in
        let red = UIColor(red: 235/255.0, green: 154/255.0, blue: 164/255.0, alpha: 1)
        let pink = UIColor(red: 242/255.0, green: 170/255.0, blue: 244/255.0, alpha: 1)
        let blue = UIColor(red: 136/255.0, green: 164/255.0, blue: 229/255.0, alpha: 1)
        let yellow = UIColor(red: 227/255.0, green: 219/255.0, blue: 183/255.0, alpha: 1)
        return [blue, red, yellow, red, blue, blue, red, blue, pink, blue, red, blue][(48 - 7*i + 4*j) % 12]
    }
    
    // piano-like layout with a vertical period
    static let bosanquetWilson12 = Keymap("Bosanquet Wilson", tuning: 12) { i, j in
        UInt8( 36 - i + 2*j )
    } color: { i, j in
        let lightBlue = UIColor(red: 202/255.0, green: 219/255.0, blue: 245/255.0, alpha: 1)
        let darkBlue = UIColor(red: 97/255.0, green: 136/255.0, blue: 241/255.0, alpha: 1)
        let a = (36 - i + 2*j) % 12
        let b = a%2 == 0 ? a : 9-a
        return b < 5 ? lightBlue : darkBlue
    }
    
    // altered piano-like layout with a horizontal period
    static let wickiHayden12 = Keymap("Wicki Hayden", tuning: 12) { i, j in
        UInt8( 89 - 7*i + 2*j )
    } color: { i, j in
        let lightBlue = UIColor(red: 156/255.0, green: 190/255.0, blue: 249/255.0, alpha: 1)
        let darkBlue = UIColor(red: 114/255.0, green: 131/255.0, blue: 217/255.0, alpha: 1)
        let lightRed = UIColor(red: 218/255.0, green: 170/255.0, blue: 158/255.0, alpha: 1)
        let darkRed = UIColor(red: 187/255.0, green: 147/255.0, blue: 137/255.0, alpha: 1)
        let t = (89 - 7*i + 2*j) % 12
        return t%2==0 ? t <= 4 ? lightBlue : darkRed
                      : t <= 3 ? lightRed : darkBlue
    }
    
    // piano-like layout for 31edo
    static let bosanquetWilson31 = Keymap("Bosanquet Wilson 31", tuning: 31) { i, j in
        UInt8(clamping: 91 - 2*i + 5*j )
    } color: { i, j in
        let cy = UIColor(red: 142/255.0, green: 205/255.0, blue: 227/255.0, alpha: 1)
        let gr = UIColor(red: 128/255.0, green: 191/255.0, blue: 189/255.0, alpha: 1)
        let bl = UIColor(red: 139/255.0, green: 180/255.0, blue: 245/255.0, alpha: 1)
        let pr = UIColor(red: 167/255.0, green: 137/255.0, blue: 248/255.0, alpha: 1)
        let ne = UIColor(red: 158/255.0, green: 197/255.0, blue: 240/255.0, alpha: 1)
        return [ne, gr, pr, cy, bl,
                ne, gr, pr, cy, bl,
                ne, cy, pr, ne, gr,
                pr, cy, bl, ne, gr,
                pr, cy, bl, ne, gr,
                pr, cy, bl, ne, cy, pr][(91 - 2*i + 5*j) % 31]
    }
}
// two classes or (UInt8, UIColor)?
