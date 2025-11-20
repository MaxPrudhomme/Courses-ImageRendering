//
//  MetalTypes.swift
//  IR-Raytracing
//
//  Created by AI Assistant on 20/11/2025.
//

import simd

struct GPUSphere {
    var center: SIMD3<Float>
    var radius: Float
    var color: SIMD3<Float>
    var material: Int32
    var ior: Float
    var padding: SIMD3<Float> = .zero
    
    init(sphere: Sphere) {
        self.center = sphere.center
        self.radius = sphere.radius
        self.color = sphere.color
        switch sphere.material {
        case .metal: self.material = 0
        case .glass: self.material = 1
        case .matte: self.material = 2
        }
        self.ior = sphere.ior
    }
}

struct GPUPlane {
    var origin: SIMD3<Float>
    var padding1: Float = 0
    var normal: SIMD3<Float>
    var padding2: Float = 0
    var color: SIMD3<Float>
    var material: Int32
    var ior: Float
    var padding3: SIMD3<Float> = .zero
    
    init(plane: Plane) {
        self.origin = plane.origin
        self.normal = plane.normal
        self.color = plane.color
        switch plane.material {
        case .metal: self.material = 0
        case .glass: self.material = 1
        case .matte: self.material = 2
        }
        self.ior = plane.ior
    }
}

struct GPULight {
    var origin: SIMD3<Float>
    var intensity: Float
    var radius: Float
    var padding: SIMD3<Float> = .zero
    
    init(light: Light) {
        self.origin = light.origin
        self.intensity = light.intensity
        self.radius = light.radius
    }
}

