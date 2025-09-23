//
//  Light.swift
//  IR-TP1
//
//  Created by Max PRUDHOMME on 16/09/2025.
//

class Light {
    var values: SIMD4<Float> = .zero
    var intensity: Float = 0
    var absorption: Float = 0

    init(values: SIMD4<Float>, intensity: Float, absorption: Float) {
        self.values = values
        self.intensity = intensity
        self.absorption = absorption
    }
}
