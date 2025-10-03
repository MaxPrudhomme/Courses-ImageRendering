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
