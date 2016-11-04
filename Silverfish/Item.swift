//
//  MainPageItem.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 07.05.16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class Item: NSObject {
    
    var itemTitle: String?
    var itemPoster: String?
    var itemLink: String?
    
    var tag: Int?
    
    // for details view
    var hasDetails: Bool! = false
    var itemid: String?
    var name: String?
    var altName: String?
    var genre: String?
    var year: String?
    var country: String?
    var director: String?
    var actors: String?
    var thumbsUrl: [String]?
    var ratingValue: Float?
    var upVoteValue: String?
    var downVoteValue: String?
    var itemDescription: String!
    var duration: String?
    var similarItems: [Item]?
    
    
    // for favorites
    var categoryName: String?
    
    // files
    var folderId: String! = "0"
    
    override var description: String {
        return  "Title: \(itemTitle) " +
                "Image: \(itemPoster) " +
                "Link: \(itemLink)"
    }
}