//
//  ItemView.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 5/10/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class ItemView: UIView {
    private var posterImage: UIImageView!
    private var indicator: UIActivityIndicatorView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    init(frame: CGRect, posterURL: String) {
        super.init(frame: frame)
        commonInit()
        posterImage.addObserver(self, forKeyPath: "image", options: .New, context: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("DownloadImageNotification", object: self, userInfo: ["imageView": posterImage, "coverUrl": posterURL])
    }
            
    deinit {
        posterImage.removeObserver(self, forKeyPath: "image")
    }
    
    func commonInit() {
        self.backgroundColor = UIColor(red: 31/255, green: 36/255, blue: 44/255, alpha: 1.0)
        self.opaque = true
       
        posterImage = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        posterImage.contentMode = .ScaleAspectFill
        posterImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(posterImage)
        
        posterImage.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        self.addConstraint(NSLayoutConstraint(item: posterImage, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: posterImage, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: posterImage, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: posterImage, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: 0))

        indicator = UIActivityIndicatorView()
        indicator.center = center
        indicator.activityIndicatorViewStyle = .White
        indicator.startAnimating()
        addSubview(indicator)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "image" {
            indicator.stopAnimating()
        }
    }
}
