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
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Mobile/14E277 Safari Line/7.1.3",
        "Accept": "text/html,application/xhtml+xml,application/json,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "ru-RU,ru;q=0.9,en;q=0.8",
        "Accept-Charset": "utf-8, utf-16, *;q=0.1",
        "Accept-Encoding": "identity, *;q=0"
    ]
    
    func htmlDecode(_ html : Data) -> String {
        let decodedString = NSString(data: html, encoding: String.Encoding.utf8.rawValue)! as String
        return decodedString
    }
    
    func HTTPsendRequest(_ request: NSMutableURLRequest, callback: @escaping (Data?, URLResponse?, String?) -> Void) {
        let cacheResponse = URLCache.shared.cachedResponse(for: request as URLRequest)
        
        if cacheResponse == nil {
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            let task = session.dataTask(with: request as URLRequest, completionHandler :
            {
                data, response, error in
                if error != nil {
                    callback(nil, nil, (error!.localizedDescription) as String)
                } else {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    callback(data!, response!, nil)
                }
            })
            
            task.resume()
        } else {
            callback(cacheResponse!.data, cacheResponse?.response, nil)
        }
        
    }
    
    func HTTPGet(_ url: String, referer: String?, postParams: [String: String]?, callback: @escaping (Data?, URLResponse?, String?) -> Void) {
        
        //let request = NSMutableURLRequest(url: URL(string: url)!)
        let request = NSMutableURLRequest(url: URL(string: url)!, cachePolicy: NSURLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 60)
        
        if postParams != nil {
            print("This is POST request")
            var components = URLComponents()
            let cs = CharacterSet.urlFragmentAllowed
            components.percentEncodedFragment = postParams?.map { (key, value) -> String in
                key.addingPercentEncoding(withAllowedCharacters: cs)! + "=" + value.addingPercentEncoding(withAllowedCharacters: cs)!
            }.joined(separator: "&")
            request.httpBody = components.percentEncodedFragment?.data(using: .utf8)
            headers.updateValue("application/x-www-form-urlencoded", forKey: "Content-Type")
            request.httpMethod = "POST"
        } else if headers.index(forKey: "Content-Type") != nil {
            print("This is GET request")
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
    
    func HTTPGetDocumentCookie(url: String, referer: String, options: [String : String]?, callback: @escaping (Data?, URLResponse?, String?) -> Void) {
        guard let cookies = HTTPCookieStorage.shared.cookies(for: URL(string: url)!) else { return }
        let request = NSMutableURLRequest(url: URL(string: url)!, cachePolicy: NSURLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 40)
        request.addValue(referer, forHTTPHeaderField: "Referer")
        request.httpMethod = "GET"
        
        if let opt = options {
            request.setValuesForKeys(opt)
        }
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        HTTPsendRequest(request, callback: callback)
    }
    
    func getImage(_ url: String, callback: @escaping (Data?, URLResponse?, String?) -> Void) {
        let fullUrl = getFullUrl(url)
        let request = NSMutableURLRequest(url: URL(string: fullUrl)!, cachePolicy: NSURLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 60)
        
        request.httpShouldHandleCookies = false
        request.httpShouldUsePipelining = true
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        HTTPsendRequest(request, callback: callback)
    }
}
