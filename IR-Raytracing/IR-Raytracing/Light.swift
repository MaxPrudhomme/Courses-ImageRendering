//
//  Light.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 21/10/2025.
//

class Light {
    var origin: SIMD3<Float>
    var intensity: Float
    
    init(origin: SIMD3<Float> = .zero, intensity: Float  = 100) {
        self.origin = origin
        self.intensity = intensity
    }
}
