//
//  DescriptionCell.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 6/17/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class DescriptionCell: UITableViewCell {
    
    @IBOutlet weak var descriptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
