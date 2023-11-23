//  SubtitlesRecognizer.swift
//  imagesub2srt
//  Created by DimaM on 08.10.2023.

import Foundation

class SubtitlesRecognizer {
    
    private let decoder: SubtitlesDecoder
    init(url: URL, index: Int?) {
        self.decoder = SubtitlesDecoder(url: url, index: index)
    }
    
    // MARK: Public section
    public struct TextSubtitle {
        var texts: [String]
        var from: TimeInterval
        var to: TimeInterval
    }
    
    public func forEachSubtitle(closure: (TextSubtitle) -> (Void)) throws {
        while let subtitleData = try decoder.getSubtitleData() {
            try autoreleasepool {
                if let textSubtitle = try getTextSubtitle(subtitleData: subtitleData) {
                    closure(textSubtitle)
                }
            }
        }
    }
    
    func open() throws {
        try decoder.open()
    }
    
    private let subtitlesImages = SubtitlesImages()
    private let subtitlesVision = SubtitlesVision()
    private func getTextSubtitle(subtitleData: SubtitleData) throws -> TextSubtitle? {
        guard let cgImage = subtitlesImages.createCGImage(data: subtitleData.data, width: subtitleData.width, height: subtitleData.height, isDVDSubtitle: decoder.isDVDSubtitles) else { return nil }
        guard let texts = try? subtitlesVision.recognize(cgImage: cgImage), !texts.isEmpty else { return nil }
        
        let from = TimeInterval(millisecond: subtitleData.pts)
        let to = TimeInterval(millisecond: subtitleData.pts + subtitleData.duration)
        return TextSubtitle(texts: texts, from: from, to: to)
    }
    
    // Get CGImage objects who want to see raw subtitle images
    /* func forEachSubtitle(closure: (CGImage) -> (Void)) throws {
        while let subtitleData = try decoder.getSubtitleData() {
            if let cgImage = try getImageSubtitle(subtitleData: subtitleData) {
                closure(cgImage)
            }
        }
    }
    
    private func getImageSubtitle(subtitleData: SubtitleData) throws -> CGImage? {
        return subtitlesImages.createCGImage(data: subtitleData.data, width: subtitleData.width, height: subtitleData.height)
    } */
}

private extension TimeInterval {
    init(millisecond: Int) {
        self = TimeInterval(millisecond)/1000
    }
}
