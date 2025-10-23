//  Sphere.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 03/10/2025.
//

import simd

class Sphere: Object {
    var center: SIMD3<Float>
    var radius: Float
    
    init(center: SIMD3<Float>, radius: Float,
         color: SIMD3<Float> = .one, material: material = .matte) {
        self.center = center
        self.radius = radius
        super.init(color: color, material: material)
    }
    
    func hit(ray: Ray) -> Hit? {
        let oc = center - ray.origin
        let r2 = radius * radius
        let a = dot(ray.direction, ray.direction)
        let b = -2.0 * dot(ray.direction, oc)
        let c = dot(oc, oc) - r2
        let delta = b * b - 4 * a * c
        
        if delta < 0 { return nil }
        
        let sqrtD = sqrt(delta)
        var t = (-b - sqrtD) / (2.0 * a)
        if t < 0 {
            t = (-b + sqrtD) / (2.0 * a)
            if t < 0 { return nil }
        }
        
        let point = ray.origin + t * ray.direction
        let normal = normalize(point - center)
        return Hit(l: t, point: point, normal: normal, color: color)
    }
}
