//
//  Object.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 23/10/2025.
//

enum material {
    case metal
    case glass
    case matte
}

class Object {
    var color: SIMD3<Float>
    var material: material
    
    init(color: SIMD3<Float> = .zero, material: material = .matte) {
        self.color = color
        self.material = material
    }
}
