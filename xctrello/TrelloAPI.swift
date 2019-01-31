//
//  TrelloAPI.swift
//  xctrello
//
//  Created by Mats Mollestad on 30/01/2019.
//  Copyright © 2019 Mats Mollestad. All rights reserved.
//

import Foundation

class TrelloAPI {

    typealias PathEndpoint = String

    enum Result<T> {
        case success(T)
        case failure(Error)
    }

    enum Errors: Error {
        case unknown
    }

    private struct Endpoints {

        static func list(with id: String) -> String {
            return "lists/" + id
        }

        static func lists(boardID: String) -> String {
            return Endpoints.board + "/\(boardID)/lists"
        }

        static func cards(boardID: String) -> String {
            return Endpoints.board + "/\(boardID)/cards"
        }

        static func cards(listID: String) -> String {
            return list(with: listID) + "/cards"
        }

        static let cards = "cards"

        static let personalBoards = "members/me/boards"

        static let board = "boards"
    }

    private let baseURL = URL(string: "https://api.trello.com/1")!

    let decoder = JSONDecoder()
    let token: String
    let key: String


    init(token: String, key: String) {
        self.token = token
        self.key = key
    }


    func upload(_ card: TrelloCard) {
        let semaphor = DispatchSemaphore(value: 0)
        upload(to: Endpoints.cards, with: card) { (result) in
            switch result {
            case .success(_): print("+ Failed Test Card")
            case .failure(let error): print("\n\nError:", error)
            }
            semaphor.signal()
        }
        semaphor.wait()
    }

    func fetchCards(for boardID: String) {
        fetch(from: Endpoints.cards(boardID: boardID)) { (result: Result<[TrelloList]>) in
            switch result {
            case .success(let boards):
                print(boards)
            case .failure(let error):
                print(error)
            }
        }
    }

    func fetchLists(for boardID: String, completion: @escaping ((Result<[TrelloList]>) -> Void)) {
        fetch(from: Endpoints.lists(boardID: boardID), completion: completion)
    }

    func fetchBoards(completion: @escaping ((Result<[TrelloBoard]>) -> Void)) {
        fetch(from: Endpoints.personalBoards, completion: completion)
    }


    private func upload(to path: PathEndpoint, with data: URLQueryable, completion: @escaping ((Result<Void>) -> Void)) {
        let session = URLSession(configuration: .default)
        let url = baseURL.appendingPathComponent(path)
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            completion(.failure(Errors.unknown))
            return
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: key),
            URLQueryItem(name: "token", value: token),
            ] + data.queryItems
        guard let requestURL = urlComponents.url else {
            completion(.failure(Errors.unknown))
            return
        }
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        session.dataTask(with: urlRequest) { (data, response, error) in
            do {
                if let error = error {
                    throw error
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }


    private func fetch<T: Codable>(from path: PathEndpoint, completion: @escaping ((Result<T>) -> Void)) {
        let session = URLSession(configuration: .default)
        let url = baseURL.appendingPathComponent(path)
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            completion(.failure(Errors.unknown))
            return
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: key),
            URLQueryItem(name: "token", value: token),
        ]
        guard let requestURL = urlComponents.url else {
            completion(.failure(Errors.unknown))
            return
        }
        session.dataTask(with: requestURL) { [weak self] (data, response, error) in
            do {
                if let error = error {
                    throw error
                }
                guard let data = data else {
                    throw Errors.unknown
                }
                guard let result = try self?.decoder.decode(T.self, from: data) else {
                    throw Errors.unknown
                }
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
            }.resume()
    }
}
