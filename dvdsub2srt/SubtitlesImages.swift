//  SubtitlesImages.swift
//  imagesub2srt
//  Created by DimaM on 11.10.2023.

import Foundation
import CoreImage

class SubtitlesImages {

    func createCGImage(data: CFData, width: Int, height: Int, isDVDSubtitle: Bool) -> CGImage? {
        guard let image = createCGImage(data: data, width: width, height: height) else { return nil }
        
        return isDVDSubtitle ? filter(cgImage: image) : image
    }

    func createCGImage(data: CFData, width: Int, height: Int) -> CGImage? {
        let bytesPerRow = width * 4
        let space = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue)
            .union(.byteOrderDefault)
        guard let provider = CGDataProvider(data: data) else { return nil }
        
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: bytesPerRow, space: space, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
        
    private let ciContext = CIContext()
    private func filter(cgImage: CGImage) -> CGImage {
        let ciImage = CIImage(cgImage: cgImage)
        guard let filteredImage = filter(ciImage: ciImage) else { return cgImage }
        guard let image = ciContext.createCGImage(filteredImage, from: filteredImage.extent) else { return cgImage }
        return image
    }
    
    private func filter(ciImage: CIImage) -> CIImage? {
        let parameters: [String: Any] = [kCIInputImageKey: ciImage, kCIInputContrastKey: 1.6, kCIInputBrightnessKey: 0.4]
        guard let colorControlsFilter = CIFilter(name: "CIColorControls", parameters: parameters) else { return nil }
        guard let contrastImage = colorControlsFilter.outputImage else { return nil }
        
        guard let colorInvertFilter = CIFilter(name: "CIColorInvert", parameters: [kCIInputImageKey: contrastImage]) else { return nil }
        return colorInvertFilter.outputImage
    }
}
