//
//  Triangle.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 20/11/2025.
//

import simd

class Triangle: Object {
    var p0: SIMD3<Float>
    var p1: SIMD3<Float>
    var p2: SIMD3<Float>
    var normal: SIMD3<Float>
    
    init(p0: SIMD3<Float>, p1: SIMD3<Float>, p2: SIMD3<Float>, normal: SIMD3<Float>,
         color: SIMD3<Float> = .one, material: Material = .matte) {
        self.p0 = p0
        self.p1 = p1
        self.p2 = p2
        self.normal = normal
        super.init(color: color, material: material)
    }
}
