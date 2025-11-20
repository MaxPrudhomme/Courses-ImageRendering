//
//  ContentView.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 03/10/2025.
//

import SwiftUI

struct ContentView: View {
    var scene: RayTracingScene
    var image: CGImage?

    init() {
        let spheres = [
            Sphere(center: SIMD3<Float>(100, -50, 250), radius: 75, color: SIMD3<Float>(1, 1, 1), material: .metal),
            Sphere(center: SIMD3<Float>(-100, -50, 250), radius: 75, color: SIMD3<Float>(1, 1, 1), material: .glass)
        ]
        let planes = [
            Plane(origin: SIMD3<Float>(0, 0, 400), normal: SIMD3<Float>(0, 0, -1), color: SIMD3<Float>(1, 0, 1)),
            Plane(origin: SIMD3<Float>(0, 0, 0), normal: SIMD3<Float>(0, 0, 1), color: SIMD3<Float>(1, 0, 0)),
            Plane(origin: SIMD3<Float>(0, 200, 0), normal: SIMD3<Float>(0, -1, 0), color: SIMD3<Float>(1, 1, 1)),
            Plane(origin: SIMD3<Float>(0, -200, 0), normal: SIMD3<Float>(0, 1, 0), color: SIMD3<Float>(1, 1, 1)),
            Plane(origin: SIMD3<Float>(200, 0, 0), normal: SIMD3<Float>(-1, 0, 0), color: SIMD3<Float>(1, 1, 0)),
            Plane(origin: SIMD3<Float>(-200, 0, 0), normal: SIMD3<Float>(1, 0, 0), color: SIMD3<Float>(0, 1, 1))
        ]
        let lights = [Light(origin: SIMD3<Float>(0, 25, 200), intensity: 30000)]
        
        // Create and configure meshes
        var meshes: [Mesh] = []
        
        do {
            let mesh = Mesh()
            try mesh.load(named: "cube")
            mesh.center()  // Center at origin
            mesh.normalize()  // Normalize to unit size
            // mesh.makeNormals()  // Compute smooth normals (Commented out for flat shading on cube)
            
            // Apply transformations
            mesh.position = SIMD3<Float>(0, 0, 50)
            mesh.scale = SIMD3<Float>(10, 10, 10)
            mesh.color = SIMD3<Float>(0, 1, 0)
            mesh.material = .matte
            
            meshes.append(mesh)
        } catch {
            print("Failed to load mesh: \(error)")
        }
        
        self.scene = Scene_Five(s: spheres, p: planes, l: lights, m: meshes)
        self.image = scene.render(size: 512)
    }
    
    var body: some View {
        VStack {
            if let image = image {
                Image(decorative: image, scale: 1.0, orientation: .up)
                    .resizable()
                    .interpolation(.high) // Smoother scaling
                    .scaledToFit()
                    .frame(width: 512, height: 512)
                    .cornerRadius(8)
            } else {
                Text("No image available")
                    .foregroundStyle(.secondary)
                    .frame(width: 512, height: 512)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
