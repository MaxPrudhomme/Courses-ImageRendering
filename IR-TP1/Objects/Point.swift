//
//  Point.swift
//  IR-TP1
//
//  Created by Max PRUDHOMME on 16/09/2025.
//

import simd

class Point {
    var raw : SIMD3<Float>
    
    init(raw : SIMD3<Float>) {
        self.raw = SIMD3(raw.x, raw.y, raw.z)
    }
    
    func translate(dir: Direction, distance: Float = 1.0) {
        raw += normalize(dir.raw) * distance
    }
}
