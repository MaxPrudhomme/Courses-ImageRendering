//
//  Scene_One.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 03/10/2025.
//

import simd
import CoreGraphics

class Scene_One {
    var spheres: [Sphere] = []
    
    init(centers: [SIMD3<Float>]?, radiuses: [Float]?) {
        guard let centers = centers, let radiuses = radiuses else {
            spheres.append(Sphere(center: SIMD3<Float>(0, 0, 0), radius: 1))
            return
        }
        
        let amount: Int = min(centers.count, radiuses.count)
        
        for i in 0..<amount {
            spheres.append(Sphere(center: centers[i], radius: radiuses[i]))
        }
    }
    
    func trace(ray: Ray) -> SIMD4<UInt8> {
        var closest: Hit? = nil
        
        for sphere in spheres {
            if let current = sphere.hit(ray: ray) {
                if closest == nil {
                    closest = current
                } else if let old = closest {
                    if current.l < old.l {
                        closest = current
                    }
                }
            }
        }
        
        if let hit = closest {
            let t = min(255, Int(hit.l))
            return SIMD4<UInt8>(UInt8(t), UInt8(t), UInt8(t), 255)
        } else {
            return SIMD4<UInt8>(255, 0, 0, 255)
        }
    }
    
    func render(size: Int) -> CGImage? {
        var buffer = Array(repeating: SIMD4<UInt8>.zero, count: size * size)
        let camera: SIMD3<Float> = .zero
        
        for y in 0..<size {
            for x in 0..<size {
                let u = 2 * Float(x) / Float(size) - 1
                let v = 1 - 2 * Float(y) / Float(size)
                
                let direction = normalize(SIMD3<Float>(u, v, 1))
                let ray = Ray(direction: direction, origin: camera)
                
                buffer[y * size + x] = trace(ray: ray)
            }
        }
        
        
        return toCGImage(buffer: buffer, size: size)
    }
}
