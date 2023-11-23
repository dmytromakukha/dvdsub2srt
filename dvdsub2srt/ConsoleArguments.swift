//  ConsoleArguments.swift
//  imagesub2srt
//  Created by DimaM on 10.10.2023.

import Foundation

extension ConsoleApplication {
    
    // A simple command line argument parser
    struct Arguments {
        let streamIndex: Int?
        let path: String?
        
        init(_ arguments: [String]) {
            var waitForStreamIndexArgument = false
            var streamIndex: Int?
            var path: String?
            var skipFirst = true
            for argument in arguments {
                if skipFirst { skipFirst = false; continue }
                
                if waitForStreamIndexArgument {
                    waitForStreamIndexArgument = false
                    streamIndex = Int(argument)
                    continue
                }
                
                if argument=="-s" {
                    waitForStreamIndexArgument = true
                    continue
                } else {
                    path = argument
                }
            }
            
            self.streamIndex = streamIndex
            self.path = path
        }
    }
}
