//
//  ItemView.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 5/10/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class ItemView: UIView {
    fileprivate var posterImage: UIImageView!
    fileprivate var indicator: UIActivityIndicatorView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    init(frame: CGRect, posterURL: String) {
        super.init(frame: frame)
        commonInit()
        posterImage.addObserver(self, forKeyPath: "image", options: .new, context: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadImageNotification"), object: self, userInfo: ["imageView": posterImage, "coverUrl": posterURL])
    }
            
    deinit {
        posterImage.removeObserver(self, forKeyPath: "image")
    }
    
    func commonInit() {
        self.backgroundColor = UIColor(red: 31/255, green: 36/255, blue: 44/255, alpha: 1.0)
        self.isOpaque = true
       
        posterImage = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        posterImage.contentMode = .scaleAspectFill
        posterImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(posterImage)
        
        posterImage.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        self.addConstraint(NSLayoutConstraint(item: posterImage, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: posterImage, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: posterImage, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: posterImage, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0))

        indicator = UIActivityIndicatorView()
        indicator.center = center
        indicator.activityIndicatorViewStyle = .white
        indicator.startAnimating()
        addSubview(indicator)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "image" {
            indicator.stopAnimating()
            indicator.removeFromSuperview()
        }
    }
}
