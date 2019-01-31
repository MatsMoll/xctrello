//
//  ShellCommand.swift
//  xctrello
//
//  Created by Mats Mollestad on 30/01/2019.
//  Copyright © 2019 Mats Mollestad. All rights reserved.
//

import Foundation


class ShellCommand {
    let launchPath: String
    let arguments: [String]

    init(arguments: String..., launchPath: String = "") {
        self.launchPath = launchPath
        self.arguments = arguments
    }

    func run(input: Pipe? = nil) -> String? {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = launchPath
        task.arguments = arguments
        task.standardOutput = pipe
        task.standardInput = input
        task.standardError = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}
