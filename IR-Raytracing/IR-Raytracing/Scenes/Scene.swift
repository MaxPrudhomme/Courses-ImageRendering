//
//  Scene.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 20/11/2025.
//

import simd
import CoreGraphics

class RayTracingScene {
    var objects: [Object] = []
    var lights: [Light] = []
    
    init() {
        // Base initializer - subclasses should override
    }
    
    func render(size: Int) -> CGImage? {
        let tracer = MetalRayTracer()
        return tracer.render(scene: self, size: size)
    }
}

