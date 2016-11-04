//
//  ZoomSegue.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 5/12/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class ZoomSegue: UIStoryboardSegue {
    
//    override func perform() {
//        // Assign the source and destination views to local variables.
//        let sourceVC = self.sourceViewController.view as UIView!
//        let destinationVC = self.destinationViewController.view as UIView!
//        
//        // Get the screen width and height.
//        let screenWidth = UIScreen.mainScreen().bounds.size.width
//        let screenHeight = UIScreen.mainScreen().bounds.size.height
//        
//        // Specify the initial position of the destination view.
//        destinationVC.frame = CGRectMake(sourceVC.bounds.minX, sourceVC.bounds.minY, sourceVC.bounds.size.width, sourceVC.bounds.size.height)
//        
//        // Access the app's key window and insert the destination view above the current
//        let window = UIApplication.sharedApplication().keyWindow
//        window?.insertSubview(destinationVC, aboveSubview: sourceVC)
//        
//        // Animate the transition.
//        UIView.animateWithDuration(0.4, delay: 0.0, options: .CurveEaseIn, animations: { 
//            
//            // add Zoom animation
//            
//            }) { (finished) in
//                
//            // present destinationVC
//                
//        }
//        
//        UIView.animateWithDuration(0.4, animations: { () -> Void in
//            destinationVC.transform = CGAffineTransformScale(destinationVC.transform, 1, 1)
//            destinationVC.frame = CGRectOffset(sourceVC.frame, -screenWidth, -screenHeight)
//        }) { (Finished) -> Void in
//            self.sourceViewController.presentViewController(self.destinationViewController as UIViewController,
//                                                            animated: false,
//                                                            completion: nil)
//        }
//    }
    
    override func perform() {
        let fromView = sourceViewController.view
        let toView = destinationViewController.view
        if let containerView = fromView.superview {
            let initialFrame = fromView.frame
            var offscreenRect = initialFrame
            offscreenRect.origin.x -= CGRectGetWidth(initialFrame)
            toView.frame = offscreenRect
            containerView.addSubview(toView)
            // Being explicit with the types NSTimeInterval and CGFloat are important
            // otherwise the swift compiler will complain
            let duration: NSTimeInterval = 1.0
            let delay: NSTimeInterval = 0.0
            let options = UIViewAnimationOptions.CurveEaseInOut
            let damping: CGFloat = 0.5
            let velocity: CGFloat = 4.0
            UIView.animateWithDuration(duration, delay: delay, usingSpringWithDamping: damping,
                                       initialSpringVelocity: velocity, options: options, animations: {
                                        toView.frame = initialFrame
                }, completion: { finished in
                    toView.removeFromSuperview()
                    if let navController = self.destinationViewController.navigationController {
                        navController.popToViewController(self.destinationViewController, animated: false)
                    }
            })
        }
    }

}
