//
//  LoadingView.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 5/12/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

public class LoadingView{
    
    var overlayView = UIView()
    var activityIndicator = UIActivityIndicatorView()
    
    static var shared = LoadingView()
    
    public func showOverlay(view: UIView) {
        
        //let mainScreen = UIScreen.mainScreen()
        
        overlayView.frame = CGRectMake(0, 0, view.bounds.width, view.bounds.height)
        overlayView.center = view.center
        overlayView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
//        overlayView.clipsToBounds = true
//        overlayView.layer.cornerRadius = 10
        
        activityIndicator.frame = CGRectMake(0, 0, 40, 40)
        activityIndicator.activityIndicatorViewStyle = .WhiteLarge
        activityIndicator.center = CGPointMake(overlayView.bounds.width / 2, overlayView.bounds.height / 2)
        
        overlayView.addSubview(activityIndicator)
        view.addSubview(overlayView)
        
        view.addConstraint(NSLayoutConstraint(item: overlayView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: overlayView, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: overlayView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: overlayView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: 0))
        
        activityIndicator.startAnimating()
    }
    
    public func hideOverlayView() {
        activityIndicator.stopAnimating()
        overlayView.removeFromSuperview()
    }
}