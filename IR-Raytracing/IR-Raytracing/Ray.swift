//
//  Ray.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 03/10/2025.
//

import simd

class Ray {
    var direction: SIMD3<Float>
    var origin: SIMD3<Float>
    
    init(direction: SIMD3<Float>, origin: SIMD3<Float>) {
        self.direction = direction
        self.origin = origin
    }
    
    func at(_ t: Float) -> SIMD3<Float> {
        return origin + t * direction
    }
}

struct Hit {
    let l: Float
    let point: SIMD3<Float>
    let normal: SIMD3<Float>
    let color: SIMD3<Float>
}
