//
//  DetailsCell.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 6/24/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class DetailsCell: UITableViewCell {
    
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var ratingBar: UIProgressView!
    @IBOutlet weak var upVoteLabel: UILabel!
    @IBOutlet weak var downVoteLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var directorsName: UILabel!
    @IBOutlet weak var actorsName: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
