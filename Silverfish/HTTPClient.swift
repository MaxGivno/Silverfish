//
//  MainViewController.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 4/14/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit
import Foundation

class HTTPClient {
    
    var headers = [
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 9_3_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13E238 Safari/601.1",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "ru-RU,ru;q=0.9,en;q=0.8",
        "Accept-Charset": "utf-8, utf-16, *;q=0.1",
        "Accept-Encoding": "identity, *;q=0"
    ]
    
    func htmlDecode(html : NSData) -> String {
        let decodedString = NSString(data: html, encoding: NSUTF8StringEncoding) as! String
        return decodedString
    }
    
    func HTTPsendRequest(request: NSMutableURLRequest, callback: (NSData?, String?) -> Void) {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let task = session.dataTaskWithRequest(request, completionHandler :
            {
                data, response, error in
                if error != nil {
                    callback(nil, (error!.localizedDescription) as String)
                } else {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    callback(data!, nil)
                }
        })
        
        task.resume()
    }
    
    func HTTPGet(url: String, referer: String?, postParams: Dictionary<String, AnyObject>?, callback: (NSData?, String?) -> Void) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        
        if postParams != nil {
            print("It is POST request")
            let postParamsEncoded = postParams!.stringFromHttpParameters()
            request.HTTPBody = postParamsEncoded.dataUsingEncoding(NSUTF8StringEncoding)
            headers.updateValue("application/x-www-form-urlencoded", forKey: "Content-Type")
            request.HTTPMethod = "POST"
        } else if headers.indexForKey("Content-Type") != nil {
            print("It is GET request")
            headers.removeValueForKey("Content-Type")
            request.HTTPMethod = "GET"
        }
        
        if referer != nil {
            request.addValue(referer!, forHTTPHeaderField: "Referer")
        }
        
        for (index, value) in headers {
            request.setValue(value, forHTTPHeaderField: index)
        }
        
        HTTPsendRequest(request, callback: callback)
    }
    
    func getImage(url: String, callback: (NSData?, String?) -> Void) {
        let fullUrl = getFullUrl(url)
        let request = NSMutableURLRequest(URL: NSURL(string: fullUrl)!)
        
        request.cachePolicy = .ReturnCacheDataElseLoad
        request.HTTPShouldHandleCookies = false
        request.HTTPShouldUsePipelining = true
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        HTTPsendRequest(request, callback: callback)
    }
}
