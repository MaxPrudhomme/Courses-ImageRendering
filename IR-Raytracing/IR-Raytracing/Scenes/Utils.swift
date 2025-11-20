//
//  Utils.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 03/10/2025.
//

import simd
import CoreGraphics
import Foundation

func toCGImage(buffer: [SIMD4<UInt8>], size: Int) -> CGImage? {
    let dataSize = buffer.count * MemoryLayout<SIMD4<UInt8>>.stride

    let cfData = buffer.withUnsafeBytes { rawBuffer in
        CFDataCreate(nil, rawBuffer.baseAddress, dataSize)
    }
    
    guard let provider = CGDataProvider(data: cfData!) else {
        return nil
    }
    
    let bitsPerComponent = 8
    let bitsPerPixel = 32
    let bytesPerRow = size * MemoryLayout<SIMD4<UInt8>>.stride
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
    
    return CGImage(
        width: size,
        height: size,
        bitsPerComponent: bitsPerComponent,
        bitsPerPixel: bitsPerPixel,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo,
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )
}


func blendColors(
    _ c1: SIMD4<UInt8>,
    _ c2: SIMD4<UInt8>,
    weight: Float
) -> SIMD4<UInt8> {
    let w1 = 1.0 - weight
    let w2 = weight

    let r = UInt8(clamping: Int(Float(c1.x) * w1 + Float(c2.x) * w2))
    let g = UInt8(clamping: Int(Float(c1.y) * w1 + Float(c2.y) * w2))
    let b = UInt8(clamping: Int(Float(c1.z) * w1 + Float(c2.z) * w2))
    let a = UInt8(clamping: Int(Float(c1.w) * w1 + Float(c2.w) * w2))

    return SIMD4<UInt8>(r, g, b, a)
}

func loadOFFFile(
    named name: String,
    withExtension ext: String = "off",
    color: SIMD3<Float> = SIMD3<Float>(0.8, 0.8, 0.8),
    material: Material = .matte,
    position: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
    scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1),
    rotation: SIMD3<Float> = SIMD3<Float>(0, 0, 0) // Euler angles in radians: pitch, yaw, roll
) -> [Triangle]? {
    guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
        print("Error: Failed to find \(name).\(ext) in bundle.")
        return nil
    }
    
    guard let content = try? String(contentsOfFile: url.path, encoding: .utf8) else {
        print("Error: Could not read file at path: \(url.path)")
        return nil
    }
    
    let lines = content.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    
    guard !lines.isEmpty else {
        print("Error: Empty file")
        return nil
    }
    
    // Check for OFF header
    var lineIndex = 0
    if lines[lineIndex].uppercased() == "OFF" {
        lineIndex += 1
    }
    
    // Parse header: numVertices numFaces numEdges
    guard lineIndex < lines.count else {
        print("Error: Missing header line")
        return nil
    }
    
    let headerComponents = lines[lineIndex].components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    guard headerComponents.count >= 2,
          let numVertices = Int(headerComponents[0]),
          let numFaces = Int(headerComponents[1]) else {
        print("Error: Invalid header format")
        return nil
    }
    
    lineIndex += 1
    
    // Parse vertices
    var vertices: [SIMD3<Float>] = []
    vertices.reserveCapacity(numVertices)
    
    for _ in 0..<numVertices {
        guard lineIndex < lines.count else {
            print("Error: Not enough vertex lines")
            return nil
        }
        
        let vertexComponents = lines[lineIndex].components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard vertexComponents.count >= 3,
              let x = Float(vertexComponents[0]),
              let y = Float(vertexComponents[1]),
              let z = Float(vertexComponents[2]) else {
            print("Error: Invalid vertex format at line \(lineIndex + 1)")
            return nil
        }
        
        var vertex = SIMD3<Float>(x, y, z)
        
        // Apply transformations
        // 1. Scale
        vertex = vertex * scale
        
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
            vertex = rotZ * rotY * rotX * vertex
        }
        
        // 3. Translation
        vertex = vertex + position
        
        vertices.append(vertex)
        lineIndex += 1
    }
    
    // Parse faces and create triangles
    var triangles: [Triangle] = []
    
    for _ in 0..<numFaces {
        guard lineIndex < lines.count else {
            print("Error: Not enough face lines")
            return nil
        }
        
        let faceComponents = lines[lineIndex].components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !faceComponents.isEmpty,
              let vertexCount = Int(faceComponents[0]),
              vertexCount >= 3 else {
            print("Error: Invalid face format at line \(lineIndex + 1)")
            lineIndex += 1
            continue
        }
        
        // Extract vertex indices
        var indices: [Int] = []
        for i in 1..<min(vertexCount + 1, faceComponents.count) {
            if let idx = Int(faceComponents[i]) {
                indices.append(idx)
            }
        }
        
        // Triangulate polygon (fan triangulation)
        if indices.count >= 3 {
            let v0 = vertices[indices[0]]
            for i in 1..<(indices.count - 1) {
                let v1 = vertices[indices[i]]
                let v2 = vertices[indices[i + 1]]
                
                // Compute normal
                let edge1 = v1 - v0
                let edge2 = v2 - v0
                let normal = normalize(cross(edge1, edge2))
                
                let triangle = Triangle(
                    p0: v0,
                    p1: v1,
                    p2: v2,
                    normal: normal,
                    color: color,
                    material: material
                )
                triangles.append(triangle)
            }
        }
        
        lineIndex += 1
    }
    
    return triangles
}
