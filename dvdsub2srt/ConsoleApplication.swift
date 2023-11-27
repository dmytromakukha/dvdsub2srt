//  ConsoleApplication.swift
//  imagesub2srt
//  Created by DimaM on 08.10.2023.

import Foundation

@main
struct ConsoleApplication {
    static func printUsageHelp() {
        print("Application for converting DVD or Blu-ray disc subtitles to text subtitles .srt")
        print("Usage: dvdsub2srt [-s stream] [-l] <path_to_video_file>")
        print("Options:")
        print("  -s <stream>  Set the stream index of subtitles to process")
        print("  -l           Show list of file streams")
    }
    
    static func main() throws {
        setlinebuf(stdout)
        
        let arguments = Arguments(CommandLine.arguments)
        guard let path = arguments.path else {
            printUsageHelp()
            exit(1)
        }
        
        let url = URL(fileURLWithPath: path)
        if arguments.showStreams {
            let streams = try ShowStreams().allStreamInfo(url: url)
            streams.forEach {
                print("Stream \($0.index)(\($0.language)): \($0.comment)")
            }
            exit(0)
        }
        
        let index = arguments.streamIndex
        let processor = SubtitlesRecognizer(url: url, index: index)
        try processor.open()
        
        var counter = 0
        try processor.forEachSubtitle { textSubtitle in
            counter += 1
            print(textSubtitle.srt(counter: counter))
        }
    }
}

private extension SubtitlesRecognizer.TextSubtitle {
    func srt(counter: Int) -> String {
        """
        \(counter)
        \(from.hourMinuteSecondComaMS) --> \(to.hourMinuteSecondComaMS)
        \(texts.map{$0}.joined(separator: "\n"))
        
        """
    }
}

private extension TimeInterval {
    var hourMinuteSecondComaMS: String {
        let hour = Int((self/3600).truncatingRemainder(dividingBy: 3600))
        let minute = Int((self/60).truncatingRemainder(dividingBy: 60))
        let second = Int(truncatingRemainder(dividingBy: 60))
        let millisecond = Int((self*1000).truncatingRemainder(dividingBy: 1000))
        return String(format:"%02d:%02d:%02d,%03d", hour, minute, second, millisecond)
    }
}
