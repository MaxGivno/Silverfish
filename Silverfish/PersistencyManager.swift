//
//  PersistencyManager.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 08.05.16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class PersistencyManager: NSObject {
    fileprivate var items = [Item]()
    fileprivate var mainPageItems = [[Item]]()
    
    func getItems() -> [Item] {
        return items
    }
    
    func addItem(_ item: Item, index: Int) {
        if (items.count >= index) {
            items.insert(item, at: index)
        } else {
            items.append(item)
        }
    }
    
    func deleteItemAtIndex(_ index: Int) {
        items.remove(at: index)
    }
    
    func getMainPageItems() -> [[Item]] {
        return mainPageItems
    }
    
    func addRowToMainPage(_ itemsArray: [Item], atIndex: Int) {
        if (mainPageItems.count >= atIndex) {
            mainPageItems.insert(itemsArray, at: atIndex)
        } else {
            mainPageItems.append(itemsArray)
        }
        
    }
    
    func clearData() {
        items.removeAll()
        mainPageItems.removeAll()
    }
    
    func saveImage(_ image: UIImage, filename: String) {
        let path = NSHomeDirectory() + "/Documents/\(filename)"
        let data = UIImagePNGRepresentation(image)
        try? data?.write(to: URL(fileURLWithPath: path), options: [.atomic])
    }
    
    func getImage(_ filename: String) -> UIImage? {
        let path = NSHomeDirectory() + "/Documents/\(filename)"
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .uncachedRead)
            return UIImage(data: data)
        } catch {
            print(">>> \(error.localizedDescription)")
            return nil
        }
    }
}
