//
//  Mesh.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 20/11/2025.
//

import simd
import Foundation

class Mesh {
    var vertices: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    var normals: [SIMD3<Float>] = []
    
    // Transformation properties
    var position: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1)
    var rotation: SIMD3<Float> = SIMD3<Float>(0, 0, 0) // Euler angles in radians: pitch, yaw, roll
    var color: SIMD3<Float> = SIMD3<Float>(0.8, 0.8, 0.8)
    var material: Material = .matte
    
    func load(named name: String, withExtension ext: String = "off") throws {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            throw NSError(domain: "Mesh", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Failed to find \(name).\(ext) in bundle."
            ])
        }
        try parse(from: url.path)
    }
    
    func parse(from path: String) throws {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        var lines = content
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        
        guard lines.first == "OFF" else {
            throw NSError(domain: "OFFParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing OFF header"])
        }
        lines.removeFirst()
        
        let counts = lines.removeFirst().split(separator: " ").compactMap { Int($0) }
        guard counts.count >= 3 else {
            throw NSError(domain: "OFFParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid counts line"])
        }
        
        let vertexCount = counts[0]
        let faceCount = counts[1]
        
        vertices.removeAll()
        for i in 0..<vertexCount {
            let parts = lines.removeFirst().split(separator: " ").compactMap { Float($0) }
            guard parts.count == 3 else {
                throw NSError(
                    domain: "OFFParser",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid vertex line \(i)"]
                )
            }
            vertices.append(SIMD3(parts[0], parts[1], parts[2]))
        }
        
        indices.removeAll()
        for i in 0..<faceCount {
            let parts = lines.removeFirst().split(separator: " ").compactMap { Int($0) }
            guard parts.count >= 4 else {
                throw NSError(
                    domain: "OFFParser",
                    code: 4,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid face line \(i)"]
                )
            }
            
            let n = parts[0]
            let faceIndices = Array(parts[1...])
            
            // Triangulate polygon (fan method)
            for j in 0..<(n - 2) {
                indices.append(UInt32(faceIndices[0]))
                indices.append(UInt32(faceIndices[j + 1]))
                indices.append(UInt32(faceIndices[j + 2]))
            }
        }
        
        normals = Array(repeating: SIMD3<Float>(0, 0, 0), count: vertices.count)
    }
    
    func center() {
        let sum = vertices.reduce(SIMD3<Float>(0, 0, 0)) { $0 + $1 }
        let center = sum / Float(vertices.count)
        
        for i in 0..<vertices.count {
            vertices[i] -= center
        }
    }
    
    func normalize() {
        let maxCoord = vertices.reduce(Float(0)) { currentMax, vertex in
            let vertexMax = max(abs(vertex.x), abs(vertex.y), abs(vertex.z))
            return max(currentMax, vertexMax)
        }
        
        guard maxCoord > 0 else { return }
        
        let scale: Float = 1.0 / maxCoord
        for i in 0..<vertices.count {
            vertices[i] *= scale
        }
    }
    
    func makeNormals() {
        var normalCounts = Array(repeating: 0, count: vertices.count)
        normals = Array(repeating: SIMD3<Float>(0, 0, 0), count: vertices.count)
        
        for i in stride(from: 0, to: indices.count, by: 3) {
            guard i + 2 < indices.count else { continue }
            
            let ia = Int(indices[i])
            let ib = Int(indices[i + 1])
            let ic = Int(indices[i + 2])
            
            guard ia < vertices.count, ib < vertices.count, ic < vertices.count else { continue }
            
            let a = vertices[ia]
            let b = vertices[ib]
            let c = vertices[ic]
            let faceNormal = simd.normalize(cross(b - a, c - a))
            
            normals[ia] += faceNormal
            normals[ib] += faceNormal
            normals[ic] += faceNormal
            normalCounts[ia] += 1
            normalCounts[ib] += 1
            normalCounts[ic] += 1
        }
        
        for i in 0..<normals.count {
            if normalCounts[i] > 0 {
                normals[i] /= Float(normalCounts[i])
                normals[i] = simd.normalize(normals[i])
            }
        }
    }
    
    func transformVertex(_ vertex: SIMD3<Float>) -> SIMD3<Float> {
        var v = vertex
        
        // 1. Scale
        v = v * scale
        
        // 2. Rotation (Euler angles: pitch, yaw, roll)
        if rotation.x != 0 || rotation.y != 0 || rotation.z != 0 {
            // Rotation around X axis (pitch)
            let cosX = cos(rotation.x)
            let sinX = sin(rotation.x)
            let rotX = simd_float3x3(
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, cosX, -sinX),
                SIMD3<Float>(0, sinX, cosX)
            )
            
            // Rotation around Y axis (yaw)
            let cosY = cos(rotation.y)
            let sinY = sin(rotation.y)
            let rotY = simd_float3x3(
                SIMD3<Float>(cosY, 0, sinY),
                SIMD3<Float>(0, 1, 0),
                SIMD3<Float>(-sinY, 0, cosY)
            )
            
            // Rotation around Z axis (roll)
            let cosZ = cos(rotation.z)
            let sinZ = sin(rotation.z)
            let rotZ = simd_float3x3(
                SIMD3<Float>(cosZ, -sinZ, 0),
                SIMD3<Float>(sinZ, cosZ, 0),
                SIMD3<Float>(0, 0, 1)
            )
            
            // Apply rotations: Z * Y * X (standard order)
            v = rotZ * rotY * rotX * v
        }
        
        // 3. Translation
        v = v + position
        
        return v
    }
    
    func toTriangles() -> [Triangle] {
        var triangles: [Triangle] = []
        
        for i in stride(from: 0, to: indices.count, by: 3) {
            guard i + 2 < indices.count else { continue }
            
            let ia = Int(indices[i])
            let ib = Int(indices[i + 1])
            let ic = Int(indices[i + 2])
            
            guard ia < vertices.count, ib < vertices.count, ic < vertices.count else { continue }
            
            // Transform vertices
            let p0 = transformVertex(vertices[ia])
            let p1 = transformVertex(vertices[ib])
            let p2 = transformVertex(vertices[ic])
            
            // Compute normal from transformed vertices
            let edge1 = p1 - p0
            let edge2 = p2 - p0
            let faceNormal = simd.normalize(cross(edge1, edge2))
            
            // Use vertex normal if available (also transform it)
            var normal = faceNormal
            if ia < normals.count && length(normals[ia]) > 0.1 {
                // Transform normal (only rotation, no translation or scale)
                var n = normals[ia]
                if rotation.x != 0 || rotation.y != 0 || rotation.z != 0 {
                    let cosX = cos(rotation.x)
                    let sinX = sin(rotation.x)
                    let rotX = simd_float3x3(
                        SIMD3<Float>(1, 0, 0),
                        SIMD3<Float>(0, cosX, -sinX),
                        SIMD3<Float>(0, sinX, cosX)
                    )
                    let cosY = cos(rotation.y)
                    let sinY = sin(rotation.y)
                    let rotY = simd_float3x3(
                        SIMD3<Float>(cosY, 0, sinY),
                        SIMD3<Float>(0, 1, 0),
                        SIMD3<Float>(-sinY, 0, cosY)
                    )
                    let cosZ = cos(rotation.z)
                    let sinZ = sin(rotation.z)
                    let rotZ = simd_float3x3(
                        SIMD3<Float>(cosZ, -sinZ, 0),
                        SIMD3<Float>(sinZ, cosZ, 0),
                        SIMD3<Float>(0, 0, 1)
                    )
                    n = simd.normalize(rotZ * rotY * rotX * n)
                }
                normal = n
            }
            
            let triangle = Triangle(
                p0: p0,
                p1: p1,
                p2: p2,
                normal: normal,
                color: color,
                material: material
            )
            triangles.append(triangle)
        }
        
        return triangles
    }
    
    func export(to path: String) throws {
        var content = "OFF\n"
        content += "\(vertices.count) \(indices.count / 3) 0\n"
        
        for vertex in vertices {
            content += "\(vertex.x) \(vertex.y) \(vertex.z)\n"
        }
        
        for i in stride(from: 0, to: indices.count, by: 3) {
            guard i + 2 < indices.count else { continue }
            let a = indices[i]
            let b = indices[i + 1]
            let c = indices[i + 2]
            content += "3 \(a) \(b) \(c)\n"
        }
        
        try content.write(toFile: path, atomically: true, encoding: .utf8)
    }
}
