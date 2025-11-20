//
//  MetalRayTracer.swift
//  IR-Raytracing
//
//  Created by AI Assistant on 20/11/2025.
//

import Metal
import MetalKit
import CoreGraphics

class MetalRayTracer {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipelineState: MTLComputePipelineState
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        
        guard let library = device.makeDefaultLibrary() else {
            print("Error: Could not load default library. Ensure .metal files are compiled.")
            fatalError("Could not load default library")
        }
        guard let kernel = library.makeFunction(name: "traceKernel") else {
            fatalError("Could not find traceKernel function")
        }
        
        do {
            self.pipelineState = try device.makeComputePipelineState(function: kernel)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }
    
    func render(scene: Scene_Four, size: Int) -> CGImage? {
        // 1. Prepare Data
        let spheres = scene.objects.compactMap { $0 as? Sphere }
        let planes = scene.objects.compactMap { $0 as? Plane }
        
        let gpuSpheres = spheres.map { GPUSphere(sphere: $0) }
        let gpuPlanes = planes.map { GPUPlane(plane: $0) }
        let gpuLights = scene.lights.map { GPULight(light: $0) }
        
        // 2. Create Output Texture
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: size, height: size, mipmapped: false)
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else { return nil }
        
        // 3. Dispatch
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return nil }
        
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(texture, index: 0)
        
        // Set Buffers
        setBuffer(encoder: encoder, data: gpuSpheres, index: 0)
        var sphereCount = UInt32(gpuSpheres.count)
        encoder.setBytes(&sphereCount, length: 4, index: 1)
        
        setBuffer(encoder: encoder, data: gpuPlanes, index: 2)
        var planeCount = UInt32(gpuPlanes.count)
        encoder.setBytes(&planeCount, length: 4, index: 3)
        
        setBuffer(encoder: encoder, data: gpuLights, index: 4)
        var lightCount = UInt32(gpuLights.count)
        encoder.setBytes(&lightCount, length: 4, index: 5)
        
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(width: (size + 15) / 16, height: (size + 15) / 16, depth: 1)
        
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // 4. Read back
        return textureToCGImage(texture: texture)
    }
    
    private func setBuffer<T>(encoder: MTLComputeCommandEncoder, data: [T], index: Int) {
        if data.isEmpty {
            let dummy = device.makeBuffer(length: max(MemoryLayout<T>.stride, 16), options: [])
            encoder.setBuffer(dummy, offset: 0, index: index)
        } else {
            let buffer = device.makeBuffer(bytes: data, length: data.count * MemoryLayout<T>.stride, options: [])
            encoder.setBuffer(buffer, offset: 0, index: index)
        }
    }
    
    private func textureToCGImage(texture: MTLTexture) -> CGImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        texture.getBytes(&data, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        
        let dataSize = data.count
        let cfData = data.withUnsafeBytes { rawBuffer in
            CFDataCreate(nil, rawBuffer.baseAddress, dataSize)
        }
        
        guard let provider = CGDataProvider(data: cfData!) else { return nil }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}

