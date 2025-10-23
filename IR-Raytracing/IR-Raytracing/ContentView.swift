//
//  ContentView.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 03/10/2025.
//

import SwiftUI

struct ContentView: View {
    var scene: Scene_Two
    var image: CGImage?

    init() {
        let spheres = [
            Sphere(center: SIMD3<Float>(100, -50, 250), radius: 75, color: SIMD3<Float>(1, 1, 1)),
            Sphere(center: SIMD3<Float>(-100, -50, 250), radius: 75, color: SIMD3<Float>(1, 1, 1))
        ]
        let planes = [
            Plane(origin: SIMD3<Float>(0, 0, 300), normal: SIMD3<Float>(0, 0, -1), color: SIMD3<Float>(1, 1, 1)),
            Plane(origin: SIMD3<Float>(0, 200, 0), normal: SIMD3<Float>(0, -1, 0), color: SIMD3<Float>(1, 1, 1)),
            Plane(origin: SIMD3<Float>(0, -200, 0), normal: SIMD3<Float>(0, 1, 0), color: SIMD3<Float>(1, 1, 1)),
            Plane(origin: SIMD3<Float>(200, 0, 0), normal: SIMD3<Float>(-1, 0, 0), color: SIMD3<Float>(1, 1, 0)),
            Plane(origin: SIMD3<Float>(-200, 0, 0), normal: SIMD3<Float>(1, 0, 0), color: SIMD3<Float>(0, 1, 1))
        ]
        let lights = [Light(origin: SIMD3<Float>(0, 25, 200), intensity: 30000)]
        
        
        self.scene = Scene_Two(s: spheres, p: planes, l: lights)
        self.image = scene.render(size: 512)
    }
    
    var body: some View {
        VStack {
            if let image = image {
                Image(decorative: image, scale: 1.0, orientation: .up)
                    .resizable()
                    .interpolation(.none)
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
