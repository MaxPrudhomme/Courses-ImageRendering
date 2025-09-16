//
//  Direction.swift
//  IR-TP1
//
//  Created by Max PRUDHOMME on 16/09/2025.
//

class Direction {
    var raw: SIMD3<Float>
    
    init(raw : SIMD3<Float>) {
        self.raw = SIMD3(raw.x, raw.y, raw.z)
    }
}
