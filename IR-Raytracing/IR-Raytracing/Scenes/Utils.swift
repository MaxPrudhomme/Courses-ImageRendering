//
//  Utils.swift
//  IR-Raytracing
//
//  Created by Max PRUDHOMME on 03/10/2025.
//

import simd
import CoreGraphics

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
