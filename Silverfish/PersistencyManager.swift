//
//  PersistencyManager.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 08.05.16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class PersistencyManager: NSObject {
    private var items = [Item]()
    private var mainPageItems = [[Item]]()
    
    func getItems() -> [Item] {
        return items
    }
    
    func addItem(item: Item, index: Int) {
        if (items.count >= index) {
            items.insert(item, atIndex: index)
        } else {
            items.append(item)
        }
    }
    
    func deleteItemAtIndex(index: Int) {
        items.removeAtIndex(index)
    }
    
    func getMainPageItems() -> [[Item]] {
        return mainPageItems
    }
    
    func addRowToMainPage(itemsArray: [Item], atIndex: Int) {
        if (mainPageItems.count >= atIndex) {
            mainPageItems.insert(itemsArray, atIndex: atIndex)
        } else {
            mainPageItems.append(itemsArray)
        }
        
    }
    
    func saveImage(image: UIImage, filename: String) {
        let path = NSHomeDirectory().stringByAppendingString("/Documents/\(filename)")
        let data = UIImagePNGRepresentation(image)
        data?.writeToFile(path, atomically: true)
    }
    
    func getImage(filename: String) -> UIImage? {
        let path = NSHomeDirectory().stringByAppendingString("/Documents/\(filename)")
        
        do {
            let data = try NSData(contentsOfFile: path, options: .UncachedRead)
            return UIImage(data: data)
        } catch {
            //print(">>> \(error)")
            return nil
        }
    }
}
