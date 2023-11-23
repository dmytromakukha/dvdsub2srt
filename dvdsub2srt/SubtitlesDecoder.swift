//  SubtitlesDecoder.swift
//  imagesub2srt
//  Created by DimaM on 09.10.2023.

import Foundation

struct SubtitleData {
    let data: CFData
    let width: Int
    let height: Int
    let pts: Int
    let duration: Int
}

class SubtitlesDecoder {
    
    var isDVDSubtitles = false
    private let url: URL
    private let index: Int?
    
    init(url: URL, index: Int?) {
        self.url = url
        self.index = index
        av_log_set_level(AV_LOG_ERROR)
    }
    
    private var format: FormatContext?
    private var decoder: CodecContext?
    private var subtitleIndex = -1
    
    func open() throws {
        format = try openInput(url: url)
        guard format != nil else { throw SubtitlesDecoderError.text("Сan't read the file: \(url.path)") }
        
        if let index {
            let isCorrectStreamIndex = try isCorrectStreamIndex(index)
            if !isCorrectStreamIndex {
                throw SubtitlesDecoderError.text("Stream '\(index)' is not correct")
            }
            let isBitmapSubtitle = try isBitmapSubtitleStream(index: index)
            if !isBitmapSubtitle {
                throw SubtitlesDecoderError.text("Stream '\(index)' is not a bitmap subtitles")
            }
            subtitleIndex = index
        } else {
            subtitleIndex = try findBitmapSubtitleStreamIndex()
        }
        
        self.decoder = try decoderForStream(index: subtitleIndex)
        self.isDVDSubtitles = try isDVDSubtitleCodecId()
    }
    
    // Once memory allocation
    private var packet = av_packet_alloc()
    private let subtitle = UnsafeMutablePointer<AVSubtitle>.allocate(capacity: MemoryLayout<AVSubtitle>.size)
    
    func getSubtitleData() throws -> SubtitleData? {
        guard let format else { throw SubtitlesDecoderError.noFormat }
        guard let decoder else { throw SubtitlesDecoderError.noDecoder }
        
        while true {
            defer { av_packet_unref(packet) }
            let error = av_read_frame(format, packet)
            guard error >= 0 else { return nil }

            if let packet, packet.pointee.stream_index == subtitleIndex {
                var got_sub: Int32 = 0
                let error = avcodec_decode_subtitle2(decoder, subtitle, &got_sub, packet)
                if error >= 0 && got_sub != 0 && subtitle.pointee.num_rects>0 {
                    defer { avsubtitle_free(subtitle) }
                    let pts = Int(packet.pointee.pts)
                    if let subtitleData = subtitleData(from: subtitle, pts: pts) {
                        return subtitleData
                    }
                }
            }
        }
    }
    
    deinit {
        subtitle.deallocate()
        av_packet_free(&packet)
        avcodec_close(decoder)
        avcodec_free_context(&decoder)
        avformat_close_input(&format)
        rawPointer.deallocate()
    }
    
    // MARK: Open media file
    private typealias FormatContext = UnsafeMutablePointer<AVFormatContext>
    private func openInput(url: URL) throws -> FormatContext? {
        var format: FormatContext?
        var error = avformat_open_input(&format, url.path, nil, nil)
        if error < 0 {
            let text = String(errorCode: error)
            throw SubtitlesDecoderError.ffmpeg("avformat_open_input() error '\(text)'")
        }
        
        guard let format else {
            throw SubtitlesDecoderError.ffmpeg("avformat_open_input() returned NULL")
        }
        
        error = avformat_find_stream_info(format, nil)
        if error < 0 {
            let text = String(errorCode: error)
            throw SubtitlesDecoderError.ffmpeg("avformat_find_stream_info() error '\(text)'")
        }
                
        return format
    }
    
    // MARK: Checking stream for required codecs
    private func isBitmapSubtitleStream(index: Int) throws -> Bool {
        guard let format else { throw SubtitlesDecoderError.noFormat}
        guard let stream = format.pointee.streams[index] else { throw SubtitlesDecoderError.noStream }
        guard let codecpar = stream.pointee.codecpar else { throw SubtitlesDecoderError.noCodecpar }
        
        let codec_id = codecpar.pointee.codec_id
        return AV_CODEC_ID_DVD_SUBTITLE == codec_id
            || AV_CODEC_ID_HDMV_PGS_SUBTITLE == codec_id
    }
    
    // MARK: Finding first stream for required codecs
    private func findBitmapSubtitleStreamIndex() throws -> Int {
        guard let format else { throw SubtitlesDecoderError.noFormat }
        
        let nb_streams = Int(format.pointee.nb_streams)
        for index in 0..<nb_streams {
            if try isBitmapSubtitleStream(index: index) {
                return index
            }
        }
        
        throw SubtitlesDecoderError.ffmpeg("Can't find stream with bitmap subtitles")
    }
    
    // MARK: Simple stream index check
    private func isCorrectStreamIndex(_ index: Int) throws -> Bool {
        guard let format else { throw SubtitlesDecoderError.noFormat }
        return index >= 0 && index < format.pointee.nb_streams
    }
    
    // MARK: Open decoder
    private typealias CodecContext = UnsafeMutablePointer<AVCodecContext>
    private func decoderForStream(index: Int) throws -> CodecContext? {
        guard let format else { throw SubtitlesDecoderError.noFormat }
        guard let stream = format.pointee.streams[index] else { throw SubtitlesDecoderError.noStream }
        guard let codecpar = stream.pointee.codecpar else { throw SubtitlesDecoderError.noCodecpar }

        let codec_id = codecpar.pointee.codec_id
        guard let codec = avcodec_find_decoder(codec_id) else {
            throw SubtitlesDecoderError.ffmpeg("avcodec_find_decoder() for AVCodecID = \(codec_id)")
        }
        
        var decoder = avcodec_alloc_context3(codec)
        if decoder == nil { throw SubtitlesDecoderError.ffmpeg("avcodec_alloc_context3() returned NULL") }
        
        let error = avcodec_open2(decoder, codec, nil)
        if error < 0 {
            avcodec_free_context(&decoder)
            let text = String(errorCode: error)
            throw SubtitlesDecoderError.ffmpeg("avcodec_open2( error '\(text)'")
        }
        
        return decoder
    }
    
    // MARK: Checking subtitle codec to AV_CODEC_ID_DVD_SUBTITLE
    private func isDVDSubtitleCodecId() throws -> Bool {
        guard let format else { throw SubtitlesDecoderError.noFormat }
        guard let stream = format.pointee.streams[subtitleIndex] else { throw SubtitlesDecoderError.noStream }
        guard let codecpar = stream.pointee.codecpar else { throw SubtitlesDecoderError.noCodecpar }
        
        return codecpar.pointee.codec_id == AV_CODEC_ID_DVD_SUBTITLE
    }
    
    // MARK: Convert AV_CODEC_ID_DVD_SUBTITLE to SubtitleData
    static let rawByteCount = 1920 * 1080 * 4
    private var rawPointer = UnsafeMutableRawPointer.allocate(byteCount: rawByteCount, alignment: MemoryLayout<Int32>.alignment)
    
    private func cfData(from rect: UnsafePointer<AVSubtitleRect>) -> CFData? {
        let capacity = Int(rect.pointee.w * rect.pointee.h)
        let buffer = rawPointer.bindMemory(to: UInt32.self, capacity: capacity)
        buffer.initialize(to: 0)
        
        guard let data0 = rect.pointee.data.0,
              let data1 = rect.pointee.data.1 else { return nil }
        let dataU32 = UnsafeRawPointer(data1).bindMemory(to: UInt32.self, capacity: capacity)
        for i in 0..<(capacity-1) {
            let p = Int(data0[i])
            let value = dataU32[p]
            buffer[i] = UInt32(bigEndian: value)
        }

        let length = capacity * 4
        let bytes = UnsafePointer(rawPointer.bindMemory(to: UInt8.self, capacity: length))
        // return CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, bytes, length, kCFAllocatorNull)
        return CFDataCreate(kCFAllocatorDefault, bytes, length)
    }
    
    private func subtitleData(from subtitle: UnsafePointer<AVSubtitle>, pts: Int) -> SubtitleData? {
        for i in 0..<Int(subtitle.pointee.num_rects) {
            guard let rect = subtitle.pointee.rects[i] else { continue }
            
            guard let data = cfData(from: rect) else { continue }
            let width = Int(rect.pointee.w)
            let height = Int(rect.pointee.h)
            let duration = Int(subtitle.pointee.end_display_time)
            return SubtitleData(data: data, width: width, height: height, pts: pts, duration: duration)
        }
        
        return nil
    }
}

enum SubtitlesDecoderError: Error {
    case text(String)
    case ffmpeg(String)
    case noFormat
    case noDecoder
    case noStream
    case noCodecpar
}

private extension String {
    init(errorCode: Int32) {
        let errbufSize = Int(AV_ERROR_MAX_STRING_SIZE)
        let errbuf = UnsafeMutablePointer<Int8>.allocate(capacity: errbufSize)
        errbuf.initialize(repeating: 0, count: errbufSize)
        self = String(cString: av_make_error_string(errbuf, errbufSize, errorCode))
        errbuf.deallocate()
    }
}
