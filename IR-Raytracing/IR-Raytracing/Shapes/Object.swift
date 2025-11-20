//
//  Object.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 23/10/2025.
//

import simd

enum Material {
    case metal
    case glass
    case matte
}

class Object {
    var color: SIMD3<Float>
    var material: Material
    var ior: Float = 1.5
    
    init(color: SIMD3<Float> = .zero, material: Material = .matte) {
        self.color = color
        self.material = material
    }
    
    func hit(ray: Ray) -> Hit? {
        fatalError("Hit from an Object should never be called.")
    }
    
    static func diffuse(hit: Hit, objects: [Object], lights: [Light]) -> SIMD4<UInt8> {
        let light = lights[0]
        
        // Direct lighting calculation
        let lightDir = light.origin - hit.point
        let distance = length(lightDir)
        let direction = normalize(lightDir)
        
        let diffuse = max(0.0, dot(hit.normal, direction))
        
        let falloff = light.intensity / (distance * distance + 20000)
        let lightContribution = diffuse * falloff
        
        // Shadow calculation
        var shadowIntensity: Float = 0.0
        let samples = 64 // Increased samples to reduce noise
        
        if light.radius > 0 {
            for _ in 0..<samples {
                let randomOffset = randomInUnitSphere() * light.radius
                let samplePoint = light.origin + randomOffset
                let sampleDir = samplePoint - hit.point
                let sampleDist = length(sampleDir)
                
                // Bias shadow ray slightly along normal to avoid self-intersection
                let shadowRay = Ray(
                    direction: normalize(sampleDir),
                    origin: hit.point + hit.normal * 0.001
                )
                
                if shadow(ray: shadowRay, objects: objects, maxDistance: sampleDist) {
                    shadowIntensity += 1.0
                }
            }
            shadowIntensity /= Float(samples)
        } else {
            let shadowRay = Ray(
                direction: normalize(lightDir),
                origin: hit.point + hit.normal * 0.001
            )
            
            if shadow(ray: shadowRay, objects: objects, maxDistance: distance) {
                shadowIntensity = 1.0
            }
        }
        
        // Combine ambient and direct lighting
        // Ambient ensures shadows aren't pitch black
        let ambient: Float = 0.1
        let totalIntensity = ambient + lightContribution * (1.0 - shadowIntensity)
        
        let finalIntensity = min(totalIntensity, 1.0)
        
        let c = hit.color
        let r = UInt8(clamping: Int(255 * c.x * finalIntensity))
        let g = UInt8(clamping: Int(255 * c.y * finalIntensity))
        let b = UInt8(clamping: Int(255 * c.z * finalIntensity))
    
        return SIMD4<UInt8>(r, g, b, 255)
    }
    
    static func light(hit: Hit, light: Light) -> SIMD4<UInt8> {
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
    }
    
    static func shadow(ray: Ray, objects: [Object], maxDistance: Float) -> Bool {
        for object in objects {
            if object.material == .glass { continue }
            if let hit = object.hit(ray: ray) {
                if hit.l < maxDistance {
                    return true
                }
            }
        }
        
        return false
    }
    
    static func reflect(hit: Hit, from: Ray, objects: [Object], lights: [Light], normal: SIMD3<Float>? = nil) -> Ray {
        let n = normal ?? hit.normal
        let rDir = from.direction - 2 * dot(from.direction, n) * n
        return Ray(direction: normalize(rDir), origin: hit.point + n * 0.001)
    }
    
    static func refract(hit: Hit, normal: SIMD3<Float>, from: Ray, n1: Float, n2: Float) -> Ray {
        let I = normalize(from.direction)
        let cos = -dot(normal, I)
        let eta = n1 / n2
        let k = 1 - eta * eta * (1 - cos * cos)
        
        if k < 0 {
            return reflect(hit: hit, from: from, objects: [], lights: [], normal: normal)
        }
        
        let dir = eta * I + (eta * cos - sqrt(k)) * normal
        let offset = normalize(dir) * 0.001
        
        return Ray(direction: normalize(dir), origin: hit.point + offset)
    }
    
    static func randomInUnitSphere() -> SIMD3<Float> {
        while true {
            let p = SIMD3<Float>(
                Float.random(in: -1...1),
                Float.random(in: -1...1),
                Float.random(in: -1...1)
            )
            if length_squared(p) < 1 {
                return p
            }
        }
    }
}
