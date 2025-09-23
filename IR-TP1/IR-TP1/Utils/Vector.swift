//
//  Vector.swift
//  IR-TP1
//
//  Created by Max PRUDHOMME on 16/09/2025.
//

import simd

struct Vector {
    var raw: SIMD4<Float>
    
    init(raw: SIMD4<Float>) {
        self.raw = raw
    }
    
    mutating func translate(_ other: Vector, distance: Float = 1.0) {
        assert(other.raw.w == 0) // must be direction
        let dir3 = normalize(SIMD3(other.raw.x, other.raw.y, other.raw.z))
        let dir4 = SIMD4(dir3 * distance, 0)
        raw += dir4
    }
}
