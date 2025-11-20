//
//  Scene_Five.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 20/11/2025.
//

import simd
import CoreGraphics

class Scene_Five: RayTracingScene {
    var maxDepth: Int = 10
    
    init(
        s: [Sphere]? = nil,
        p: [Plane]? = nil,
        l: [Light]? = nil,
        m: [Mesh]? = nil
    ) {
        super.init()
        
        let spheres: [Sphere] = s ?? []
        let planes: [Plane] = p ?? []
        let meshes: [Mesh] = m ?? []
        var triangles: [Triangle] = []

        // Convert meshes to triangles
        for mesh in meshes {
            let meshTriangles = mesh.toTriangles()
            triangles.append(contentsOf: meshTriangles)
        }

        if spheres.isEmpty && planes.isEmpty && triangles.isEmpty {
            let defaultSpheres: [Sphere] = [Sphere(center: SIMD3<Float>(0, 0, 0), radius: 1)]
            let defaultPlanes: [Plane] = [Plane(origin: SIMD3<Float>(0, 200, 0), normal: SIMD3<Float>(0, 1, 0))]
            self.objects = defaultSpheres.map { $0 as Object } + defaultPlanes.map { $0 as Object }
        } else {
            self.objects = spheres.map { $0 as Object } + planes.map { $0 as Object } + triangles.map { $0 as Object }
        }
        
        if let l = l, !l.isEmpty {
            self.lights = l
        } else {
            self.lights = [Light(origin: SIMD3<Float>(0, 0, 0))]
        }
    }
    
    func trace(ray: Ray, depth: Int) -> SIMD4<UInt8> {
        if (depth == maxDepth) {
            return SIMD4<UInt8>(0, 0, 0, 0)
        }
            
        var closest: Hit? = nil
        
        for object in objects {
            if let current = object.hit(ray: ray) {
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
            switch hit.material {
            case .metal:
                let ray = Object.reflect(hit: hit, from: ray, objects: objects, lights: lights)
                let color = trace(ray: ray, depth: depth + 1)
                let base = SIMD4<UInt8>(UInt8(hit.color.x * 255), UInt8(hit.color.y * 255), UInt8(hit.color.z * 255), 255)
                
                return blendColors(base, color, weight: 0.8)
            case .glass:
                let d = dot(ray.direction, hit.normal) < 0
                let n1 = d ? 1.0 : hit.object.ior
                let n2 = d ? hit.object.ior : 1.0
                let normal = d ? hit.normal : -hit.normal
                
                let refractRay = Object.refract(hit: hit, normal: normal, from: ray, n1: n1, n2: n2)
                return trace(ray: refractRay, depth: depth + 1)  // Pure refraction, no Fresnel
            case .matte:
                return Object.diffuse(hit: hit, objects: objects, lights: lights)
            }
        } else {
            return SIMD4<UInt8>(0, 0, 0, 255)
        }
    }
}

