//
//  Catalog.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 15.05.16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class Catalog: NSObject {
    var catalog = [[Item]]()
    
    override init() {
        let allItems = LibraryAPI.sharedInstance.getItems()
        
        for item in allItems {
            if item.tag == 0 {
                catalog[item.tag!].append(item)
            } else if item.tag == 1 {
                catalog[item.tag!].append(item)
            }
        }
        
        
    }
}
