//
//  DetailHeaderView.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 15.05.16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class DetailHeaderView: UIView {
    
    @IBOutlet weak var posterView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var altNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    var item: Item! {
        didSet {
            updateUI()
        }
    }
    
    fileprivate func updateUI() {
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //descriptionLabel.preferredMaxLayoutWidth = descriptionLabel.bounds.width
    }
    
//    deinit {
//        thumbsView.removeObserver(self, forKeyPath: "image")
//    }
}
