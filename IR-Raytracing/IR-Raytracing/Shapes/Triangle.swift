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

    // Moller-Trumbore intersection algorithm for triangle-ray hit
    override func hit(ray: Ray) -> Hit? {
        let epsilon: Float = 1e-6
        let edge1 = p1 - p0
        let edge2 = p2 - p0
        let h = cross(ray.direction, edge2)
        let a = dot(edge1, h)
        if abs(a) < epsilon { return nil }

        let f = 1.0 / a
        let s = ray.origin - p0
        let u = f * dot(s, h)
        if u < 0.0 || u > 1.0 { return nil }
        
        let q = cross(s, edge1)
        let v = f * dot(ray.direction, q)
        if v < 0.0 || u + v > 1.0 { return nil }
        
        let t = f * dot(edge2, q)
        if t < epsilon { return nil } // no intersection behind ray origin

        let hitPoint = ray.origin + t * ray.direction
        return Hit(l: t, point: hitPoint, normal: normal, color: color, material: material, object: self)
    }
}
