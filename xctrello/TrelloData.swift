//
//  TrelloData.swift
//  xctrello
//
//  Created by Mats Mollestad on 30/01/2019.
//  Copyright © 2019 Mats Mollestad. All rights reserved.
//

import Foundation

protocol URLQueryable {
    var queryItems: [URLQueryItem] { get }
}


class TrelloBoard: Codable {
    let name: String
    let id: String

    init(name: String, id: String) {
        self.name = name
        self.id = id
    }
}

class TrelloList: Codable {
    let name: String
    let id: String

    init(name: String, id: String) {
        self.name = name
        self.id = id
    }
}

class TrelloCard: Codable, URLQueryable {
    let name: String
    let description: String
    let listID: String

    init(name: String, description: String, listID: String) {
        self.name = name
        self.description = description
        self.listID = listID
    }

    var queryItems: [URLQueryItem] {
        return [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "desc", value: description),
            URLQueryItem(name: "idList", value: listID)
        ]
    }
}
