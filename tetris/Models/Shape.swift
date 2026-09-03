//
//  Shape.swift
//  tetris
//
//  Created by Rishi Jansari on 03/09/2026.
//

import Foundation

struct Shape {
    static var i: [[Bool]] = [
        [false, false, false, false],
        [true, true, true, true],
        [false, false, false, false],
        [false, false, false, false]
    ]
    
    static var j: [[Bool]] = [
        [true, false, false],
        [true, true, true],
        [false, false, false],
    ]
    
    static var l: [[Bool]] = [
        [false, false, true],
        [true, true, true],
        [false, false, false],
    ]
    
    static var o: [[Bool]] = [
        [false, true, true, false],
        [false, true, true, false],
        [false, false, false, false]
    ]
    
    static var s: [[Bool]] = [
        [false, true, true],
        [true, true, false],
        [false, false, false]
    ]
    
    static var t: [[Bool]] = [
        [false, true, false],
        [true, true, true],
        [false, false, false],
    ]
    
    static var z: [[Bool]] = [
        [true, true, false],
        [false, true, true],
        [false, false, false]
    ]
    
    static var allShapes: [[[Bool]]] = [i, j, l, o, s, t, z]
}
