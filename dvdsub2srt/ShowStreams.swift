//  ShowStreams.swift
//  Created by DimaM on 27.11.2023.

import Foundation

struct StreamInfo {
    let index: Int
    let language: String
    let comment: String
}

class ShowStreams {
    
    init() {
        av_log_set_level(AV_LOG_ERROR)
    }
    
    func allStreamInfo(url: URL) throws -> [StreamInfo] {
        var format = try openInput(url: url)
        defer { avformat_close_input(&format) }

        guard let format else {
            throw ShowStreamsError.text("Сan't read the file: \(url.path)")
        }
        
        var result = [StreamInfo]()
        let nb_streams = Int(format.pointee.nb_streams)
        for index in 0..<nb_streams {
            guard let stream = format.pointee.streams[index] else { throw ShowStreamsError.noStream }
            guard let codecpar = stream.pointee.codecpar else { throw ShowStreamsError.noCodecpar }
            
            let codec_id = codecpar.pointee.codec_id
            let metadata = stream.pointee.metadata
            let entry = av_dict_get(metadata, "language", nil, 0)
            
            let language = {
                if let value = entry?.pointee.value {
                    return String(cString: value)
                } else {
                    return "unk"
                }
            }()
            
            let comment = {
                switch codecpar.pointee.codec_type {
                case AVMEDIA_TYPE_VIDEO:
                    return "Video"
                case AVMEDIA_TYPE_AUDIO:
                    return "Audio"
                case AVMEDIA_TYPE_SUBTITLE:
                    var subtitle = "Subtitle"
                    if AV_CODEC_ID_DVD_SUBTITLE == codec_id {
                        subtitle += ", DVD disc format"
                    } else
                    if AV_CODEC_ID_HDMV_PGS_SUBTITLE == codec_id {
                        subtitle += ", Blu-ray disc format"
                    } else {
                        subtitle += ", not DVD or Blu-ray)"
                    }
                    return subtitle
                    
                default:
                    return "Unknown"
                }
            }()
            
            let streamInfo = StreamInfo(index: index, language: language, comment: comment)
            result.append(streamInfo)
        }
        
        return result
    }
    
    private typealias FormatContext = UnsafeMutablePointer<AVFormatContext>
    private func openInput(url: URL) throws -> FormatContext? {
        var format: FormatContext?
        var error = avformat_open_input(&format, url.path, nil, nil)
        if error < 0 {
            let text = String(errorCode: error)
            throw ShowStreamsError.ffmpeg("avformat_open_input() error '\(text)'")
        }
        
        guard let format else {
            throw ShowStreamsError.ffmpeg("avformat_open_input() returned NULL")
        }
        
        error = avformat_find_stream_info(format, nil)
        if error < 0 {
            let text = String(errorCode: error)
            throw ShowStreamsError.ffmpeg("avformat_find_stream_info() error '\(text)'")
        }
        
        return format
    }
}

enum ShowStreamsError: Error {
    case text(String)
    case ffmpeg(String)
    case noFormat
    case noDecoder
    case noStream
    case noCodecpar
}
