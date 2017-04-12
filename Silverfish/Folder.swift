//
//  Folder.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 4/12/17.
//  Copyright © 2017 Givno Inc. All rights reserved.
//

import UIKit

class Folder: NSObject {
    var title: String?
    var id: String! = "0"
    var folderList: [Folder]?
    var fileList: [File]?
    var info: String?
}
