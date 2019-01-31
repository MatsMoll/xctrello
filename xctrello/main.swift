#!/usr/bin/xctrello
//
//  main.swift
//  xctrello
//
//  Created by Mats Mollestad on 29/01/2019.
//  Copyright © 2019 Mats Mollestad. All rights reserved.
//

import Foundation

class Values {
    private(set) var key: String = ""
    private(set) var token: String = ""
    private(set) var listID: String?

    init(arguments: [String]) throws {

        for index in 1...arguments.dropFirst().count/2 {
            guard index * 2 < arguments.count else {
                print("Missing value after option")
                throw TrelloAPI.Errors.unknown
            }
            switch arguments[2 * index - 1] {
            case "--key", "-k": key = arguments[2 * index]
            case "--token", "-t": token = arguments[2 * index]
            case "--list", "-l": listID = arguments[2 * index]
            default: print("Unknown command", arguments[2 * index - 1])
            }
        }

        guard !key.isEmpty, !token.isEmpty else {
            throw TrelloAPI.Errors.unknown
        }
    }
}

print(CommandLine.arguments)

guard let values = try? Values(arguments: CommandLine.arguments) else {
    print("All these options are needed --key and --token\n")
    exit(1)
}

let generator = TrelloTestGenerator(values: values)


func printIDs() {
    print("Printing Trello IDS")
    let semaphore = DispatchSemaphore(value: 0)
    generator.printBoards {
        semaphore.signal()
    }
    semaphore.wait()

    print("xctrello [Trello list ID], Send one of the ID's as an argument\n")
}


if CommandLine.argc >= 2  {
    
    guard generator.listID?.count == 24 else {
        printIDs()
        print("Double check that the --list id is correct\n")
        exit(0)
    }

    let workingDir = FileManager.default.currentDirectoryPath
    let terminalFriendlyPath = workingDir.replacingOccurrences(of: " ", with: "\\ ")

    let lastTestCommand = ShellCommand(arguments: "-c", "ls -rt \(terminalFriendlyPath + "/DerivedData/Logs/Test") | grep Test-Run* | tail -1", launchPath: "/bin/bash")

    if let testFolder = lastTestCommand.run()?.replacingOccurrences(of: "\n", with: "") {
        let path = workingDir + "/DerivedData/Logs/Test/" + testFolder + "/TestSummaries.plist"
        print("DerDat: ", ShellCommand(arguments: "-c", "ls DerivedData", launchPath: "/bin/bash"))
        print("Logs: ", ShellCommand(arguments: "-c", "ls DerivedData/Logs", launchPath: "/bin/bash"))
        print("Test: ", ShellCommand(arguments: "-c", "ls DerivedData/Logs/Test", launchPath: "/bin/bash"))
        print(".xresult: ", ShellCommand(arguments: "-c", "ls DerivedData/Logs/Test/\(testFolder)/", launchPath: "/bin/bash"))
        let url = URL(fileURLWithPath: path)
        generator.generateFrom(fileAtURL: url)
    } else {
        print("\nCould not find the test summary. Make sure your in the same dir as DerivedData.")
        exit(1)
    }
} else {
    printIDs()
}
