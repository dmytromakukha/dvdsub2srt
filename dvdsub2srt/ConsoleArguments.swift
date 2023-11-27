//  ConsoleArguments.swift
//  imagesub2srt
//  Created by DimaM on 10.10.2023.

import Foundation

extension ConsoleApplication {
    
    // A simple command line argument parser
    struct Arguments {
        let streamIndex: Int?
        let path: String?
        let showStreams: Bool
        
        init(_ arguments: [String]) {
            var waitForStreamIndexArgument = false
            var streamIndex: Int?
            var path: String?
            var showStreams = false
            for argument in arguments.dropFirst() {
                if waitForStreamIndexArgument {
                    waitForStreamIndexArgument = false
                    streamIndex = Int(argument)
                    continue
                }
                
                switch argument {
                case "-s":
                    waitForStreamIndexArgument = true
                case "-l":
                    showStreams = true
                default:
                    path = argument
                }
            }
            
            self.streamIndex = streamIndex
            self.path = path
            self.showStreams = showStreams
        }
    }
}
