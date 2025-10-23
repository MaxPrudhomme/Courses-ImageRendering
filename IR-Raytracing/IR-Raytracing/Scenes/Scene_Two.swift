//
//  Scene_Two.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 21/10/2025.
//

import simd
import CoreGraphics

class Scene_Two {
    var spheres: [Sphere] = []
    var planes: [Plane] = []
    var lights: [Light] = []
    
    init(s: [Sphere]? = nil, p: [Plane]? = nil, l: [Light]? = nil) {
        if let s = s, !s.isEmpty {
            self.spheres = s
        } else {
            self.spheres = [Sphere(center: SIMD3<Float>(0, 0, 0), radius: 1)]
        }

        if let p = p, !p.isEmpty {
            self.planes = p
        } else {
            self.planes = [Plane(origin: SIMD3<Float>(0, 200, 0), normal: SIMD3<Float>(0, 1, 0))]
        }
        
        if let l = l, !l.isEmpty {
            self.lights = l
        } else {
            self.lights = [Light(origin: SIMD3<Float>(0, 0, 0))]
        }
    }
    
    func trace(ray: Ray) -> SIMD4<UInt8> {
        var closest: Hit? = nil
        
        for sphere in spheres {
            if let current = sphere.hit(ray: ray) {
                if closest == nil {
                    closest = current
                } else if let old = closest {
                    let epsilon: Float = 0.001
                    if current.l + epsilon < old.l {
                        closest = current
                    }
                }
            }
        }
        
        for plane in planes {
            if let current = plane.hit(ray: ray) {
                if closest == nil {
                    closest = current
                } else if let old = closest {
                    let epsilon: Float = 0.001
                    if current.l + epsilon < old.l {
                        closest = current
                    }
                }
            }
        }
        
        if let hit = closest {
                let light = lights[0]
                
                let lightDir = light.origin - hit.point
                let distance = length(lightDir)
                let direction = normalize(lightDir)
                
                let diffuse = max(0.0, dot(hit.normal, direction))
                
                let falloff = light.intensity / (distance * distance + 20000)
                
                let intensity = diffuse * falloff
                
                let finalIntensity = min(intensity, 1.0)
                
                let c = hit.color
                let r = UInt8(clamping: Int(255 * c.x * finalIntensity))
                let g = UInt8(clamping: Int(255 * c.y * finalIntensity))
                let b = UInt8(clamping: Int(255 * c.z * finalIntensity))
                
                return SIMD4<UInt8>(r, g, b, 255)
            } else {
                return SIMD4<UInt8>(0, 0, 0, 0)
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

