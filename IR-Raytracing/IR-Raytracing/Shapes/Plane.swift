//
//  Plane.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 21/10/2025.
//

import simd

class Plane {
    var origin: SIMD3<Float> = .zero
    var normal: SIMD3<Float> = .zero
    var color: SIMD3<Float> = .one
    
    init(origin: SIMD3<Float>, normal: SIMD3<Float>, color: SIMD3<Float> = .one) {
        self.origin = origin
        self.normal = normal
        self.color = color
    }
    
    func hit(ray: Ray) -> Hit? {
        let d = dot(normal, ray.direction)
        if (d <= 0) { return nil }
        
        let t = dot(origin - ray.origin, normal) / d
        if t < 0 { return nil }
        
        let point = ray.origin + t * ray.direction
        
        return Hit(l: t, point: point, normal: normal, color: color)
    }
}
