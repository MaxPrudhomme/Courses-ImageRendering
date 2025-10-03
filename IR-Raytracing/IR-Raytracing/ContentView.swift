//
//  ContentView.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 03/10/2025.
//

import SwiftUI

struct ContentView: View {
    var scene: Scene_One
    var image: CGImage?

    init() {
        self.scene = Scene_One(centers: [SIMD3<Float>(0, 0, 350), SIMD3<Float>(-192, 0, 250)], radiuses: [200, 100])
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
