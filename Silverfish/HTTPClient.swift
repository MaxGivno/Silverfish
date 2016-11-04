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
    
    func htmlDecode(_ html : Data) -> String {
        let decodedString = NSString(data: html, encoding: String.Encoding.utf8.rawValue) as! String
        return decodedString
    }
    
    func HTTPsendRequest(_ request: NSMutableURLRequest, callback: @escaping (Data?, String?) -> Void) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        let task = session.dataTask(with: request as URLRequest, completionHandler :
            {
                data, response, error in
                if error != nil {
                    callback(nil, (error!.localizedDescription) as String)
                } else {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    callback(data!, nil)
                }
            })
        
        task.resume()
    }
    
    func HTTPGet(_ url: String, referer: String?, postParams: Dictionary<String, AnyObject>?, callback: @escaping (Data?, String?) -> Void) {
        
        let request = NSMutableURLRequest(url: URL(string: url)!)
        
        if postParams != nil {
            print("It is POST request")
            let postParamsEncoded = postParams!.stringFromHttpParameters()
            request.httpBody = postParamsEncoded.data(using: String.Encoding.utf8)
            headers.updateValue("application/x-www-form-urlencoded", forKey: "Content-Type")
            request.httpMethod = "POST"
        } else if headers.index(forKey: "Content-Type") != nil {
            print("It is GET request")
            headers.removeValue(forKey: "Content-Type")
            request.httpMethod = "GET"
        }
        
        if referer != nil {
            request.addValue(referer!, forHTTPHeaderField: "Referer")
        }
        
        for (index, value) in headers {
            request.setValue(value, forHTTPHeaderField: index)
        }
        
        HTTPsendRequest(request, callback: callback)
    }
    
    func getImage(_ url: String, callback: @escaping (Data?, String?) -> Void) {
        let fullUrl = getFullUrl(url)
        let request = NSMutableURLRequest(url: URL(string: fullUrl)!)
        
        request.cachePolicy = .returnCacheDataElseLoad
        request.httpShouldHandleCookies = false
        request.httpShouldUsePipelining = true
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        HTTPsendRequest(request, callback: callback)
    }
}
