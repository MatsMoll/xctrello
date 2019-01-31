//
//  TrelloTestCardGenerator.swift
//  xctrello
//
//  Created by Mats Mollestad on 30/01/2019.
//  Copyright © 2019 Mats Mollestad. All rights reserved.
//

import Foundation


class TrelloTestGenerator {

    private var tests = [TrelloCard]()

    /// The id of the trello list to add the card to
    var listID: String?

    private let api: TrelloAPI

    init(values: Values) {
        api = TrelloAPI(token: values.token, key: values.key)
        listID = values.listID
    }

    func generateFrom(fileAtURL url: URL) {
        guard let plist = NSDictionary(contentsOf: url) else {
            print("Unable to decode or find summary file")
            exit(1)
        }

        guard let summaries = plist["TestableSummaries"] as? [[String : Any]] else {
            print("Unable to decode or find the correct info")
            exit(1)
        }

        guard let listID = listID else {
            print("Missing listID, when generating data")
            exit(1)
        }
        evaluateTest(data: summaries)
        api.archiveAll(for: listID)
        uploadCards()
    }

    private func uploadCards() {
        tests.forEach() { card in
            api.upload(card)
        }
    }

    private func evaluateTest(data: [[String : Any]], testSet: [String] = []) {

        for test in data {

            let currentTestSet = testSet + [(test["TestName"] as? String) ?? ""]

            if let subtests = test["Subtests"] as? [[String : Any]] {
                evaluateTest(data: subtests, testSet: currentTestSet)
            } else if let tests = test["Tests"] as? [[String : Any]] {
                evaluateTest(data: tests, testSet: currentTestSet)
            } else if test["FailureSummaries"] as? [[String : Any]] != nil {
                generateCardFrom(data: test)
            } else {
                //                print("--------- Root")
            }
        }
    }

    private func generateCardFrom(data: [String : Any]) {

        guard let failureSummaries = data["FailureSummaries"] as? [[String : Any]] else {
            print("Unable to find failure summery")
            return
        }
        guard let testIdentifier = data["TestIdentifier"] as? String else {
            print("Unable to find test id")
            return
        }
        guard let listID = listID else {
            print("Missing ListID when creating Card")
            return
        }

        var description = ""
        for failure in failureSummaries {
            guard let lineNumber = failure["LineNumber"] as? Int else {
                print("Unable to find line number")
                return
            }
            guard let message = failure["Message"] as? String else {
                print("Unable to find failure message")
                return
            }
            guard let performanceFailure = failure["PerformanceFailure"] as? Bool else {
                print("Unable to find if performance failure")
                return
            }

            description += "Line number: \(lineNumber),\n\t\(message),\n\tPerformance Failure: \(performanceFailure)\n\n"
        }
        tests += [
            TrelloCard(name: "🛑 🚧 Failing Test:\n " + testIdentifier,
                       description: description,
                       listID: listID)
        ]
    }


    func printBoards(completion: @escaping () -> Void) {
        api.fetchBoards() { [self] (result) in
            switch result {
            case .success(let boards):
                for board in boards {
                    let semaphore = DispatchSemaphore(value: 0)
                    self.printLists(for: board) {
                        semaphore.signal()
                    }
                    semaphore.wait()
                }
            case .failure(let error):
                print(error)
            }
            completion()
        }
    }

    private func printLists(for board: TrelloBoard, completion: @escaping () -> Void) {

        api.fetchLists(for: board.id) { (result) in
            switch result {
            case .success(let lists):
                print("\n\(board.name):\n")
                print("\tLists:\n")
                for list in lists {
                    print("\t\(list.name)\n\t\t\(list.id)\n")
                }
            case .failure(let error):
                print(error)
            }
            completion()
        }
    }
}
