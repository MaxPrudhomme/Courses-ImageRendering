//
//  ContentView.swift
//  IR-TP1
//
//  Created by Max PRUDHOMME on 16/09/2025.
//

import SwiftUI
import simd

// MARK: - Dot model
struct Dot: Identifiable {
    let id = UUID()
    var position: Point
    var velocity: Direction
}

struct ContentView: View {
    @State private var dots: [Dot] = []
    @State private var timer: Timer? = nil
    
    let dotCount = 10
    let dotSize: CGFloat = 12
    let speed: Float = 2.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.ignoresSafeArea()
                
                ForEach(dots) { dot in
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(
                            x: CGFloat(dot.position.raw.x),
                            y: CGFloat(dot.position.raw.y)
                        )
                }
            }
            .onAppear {
                // Initialize dots randomly inside view bounds
                dots = (0..<dotCount).map { _ in
                    let pos = Point(
                        raw: SIMD3(
                            Float.random(in: Float(dotSize)...Float(geo.size.width - dotSize)),
                            Float.random(in: Float(dotSize)...Float(geo.size.height - dotSize)),
                            0
                        )
                    )
                    
                    let vel = Direction(
                        raw: SIMD3(
                            Float.random(in: -1...1),
                            Float.random(in: -1...1),
                            0
                        )
                    )
                    
                    return Dot(position: pos, velocity: vel)
                }
                
                // Start update loop (60 FPS)
                timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0,
                                             repeats: true) { _ in
                    updateDots(in: geo.size)
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    // MARK: - Physics update
    private func updateDots(in size: CGSize) {
        let w = Float(size.width)
        let h = Float(size.height)
        
        dots = dots.map { dot in
            let newDot = dot
            
            // move position by its velocity
            newDot.position.translate(dir: newDot.velocity, distance: speed)
            
            // bounce: if it hits any wall, reverse velocity component
            if newDot.position.raw.x < Float(dotSize) || newDot.position.raw.x > w - Float(dotSize) {
                newDot.velocity.raw.x *= -1
            }
            if newDot.position.raw.y < Float(dotSize) || newDot.position.raw.y > h - Float(dotSize) {
                newDot.velocity.raw.y *= -1
            }
            
            // keep point inside bounds
            newDot.position.raw.x = min(max(newDot.position.raw.x, Float(dotSize)), w - Float(dotSize))
            newDot.position.raw.y = min(max(newDot.position.raw.y, Float(dotSize)), h - Float(dotSize))
            
            return newDot
        }
    }
}

#Preview {
    ContentView()
}
