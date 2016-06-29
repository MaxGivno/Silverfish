//
//  SearchResultCell.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 6/15/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {
    @IBOutlet weak var posterView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var upVoteLabel: UILabel!
    @IBOutlet weak var downVoteLabel: UILabel!
    
    var item = Item()
}
