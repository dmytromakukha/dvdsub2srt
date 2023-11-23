//  SubtitlesVision.swift
//  imagesub2srt
//  Created by DimaM on 08.10.2023.

import Foundation
import Vision

class SubtitlesVision {
    
    private let sequenceRequestHandler = VNSequenceRequestHandler()
    
    func recognize(cgImage: CGImage) throws -> [String]? {
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        if #available(macOS 13.0, *) {
            textRequest.automaticallyDetectsLanguage = true
        }
        
        try sequenceRequestHandler.perform([textRequest], on: cgImage)
        
        return textRequest.results?.compactMap { $0.topCandidates(1).first?.string }
    }
}
