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
        let spheres = [Sphere(center: SIMD3<Float>(0, 0, 350), radius: 200, color: SIMD3<Float>(0.4, 0.6, 0.2))]
        let planes = [Plane(origin: SIMD3<Float>(0, 0, 200), normal: SIMD3<Float>(0, 0, 1))]
        
        
        self.scene = Scene_Two(s: spheres, p: planes)
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
