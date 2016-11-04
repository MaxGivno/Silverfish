//
//  LoadingView.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 5/12/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

open class LoadingView{
    
    var overlayView = UIView()
    var activityIndicator = UIActivityIndicatorView()
    
    static var shared = LoadingView()
    
    open func showOverlay(_ view: UIView) {
        
        //let mainScreen = UIScreen.mainScreen()
        
        overlayView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        overlayView.center = view.center
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
//        overlayView.clipsToBounds = true
//        overlayView.layer.cornerRadius = 10
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.center = CGPoint(x: overlayView.bounds.width / 2, y: overlayView.bounds.height / 2)
        
        overlayView.addSubview(activityIndicator)
        view.addSubview(overlayView)
        
        view.addConstraint(NSLayoutConstraint(item: overlayView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: overlayView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: overlayView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: overlayView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0))
        
        activityIndicator.startAnimating()
    }
    
    open func hideOverlayView() {
        activityIndicator.stopAnimating()
        overlayView.removeFromSuperview()
    }
}
