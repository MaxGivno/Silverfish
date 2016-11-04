//
//  ScriptTranslation.swift
//  fsto.viewer
//
//  Created by Maxim Ryazanov on 4/19/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit
import Kanna

extension String {
    
    /// Percent escapes values to be added to a URL query as specified in RFC 3986
    ///
    /// This percent-escapes all characters besides the alphanumeric character set and "-", ".", "_", and "~".
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// :returns: Returns percent-escaped string.
    
    func stringByAddingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        
        return self.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)
    }
    
}

extension Dictionary {
    
    /// Build string representation of HTTP parameter dictionary of keys and objects
    ///
    /// This percent escapes in compliance with RFC 3986
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// :returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped
    
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).stringByAddingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = (value as! String).stringByAddingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameterArray.joinWithSeparator("&")
    }
    
}

class ScriptTranslation {
    
    let login = "max.ryazanov"
    let password = "q3dm17"
    
    let siteUrl : String = "fs.to"
    let httpSiteUrl : String = "http://" + siteUrl
    var headers = [
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:25.0) Gecko/20100101 Firefox/25.0",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "ru-RU,ru;q=0.9,en;q=0.8",
        "Accept-Charset": "utf-8, utf-16, *;q=0.1",
        "Accept-Encoding": "identity, *;q=0"
    ]
    
    // Check if it's decoding
    func htmlEntitiesDecode(html : NSData) -> String {
        let decodedString = NSString(data: html, encoding: NSUTF8StringEncoding) as! String
        return decodedString
    }
    
    func getFullUrl(url: String) -> String {
        var url : String = url
        if url.hasPrefix("//") {
            url = "http:" + url
        }
        
        if (url.rangeOfString("://") == nil) {
            url = httpSiteUrl + url
        }
        return url
    }
    
    private func setCookies(response: NSURLResponse) {
        NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(response.URL!)
        //let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(response.URL!)
        //print(cookies)
    }
    
    func HTTPsendRequest(request: NSMutableURLRequest, callback: (String, String?) -> Void) {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        let task = session.dataTaskWithRequest(request, completionHandler :
            {
                data, response, error in
                if error != nil {
                    callback("", (error!.localizedDescription) as String)
                } else {
                    callback(NSString(data: data!, encoding: NSUTF8StringEncoding) as! String,nil)
                    self.setCookies(response!)
                }
        })
        
        task.resume()
    }
    
    func HTTPGet(url: String, referer: String, postParams: Dictionary<String, AnyObject>?, callback: (String, String?) -> Void) {
        let url = getFullUrl(url)
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        
        if !(postParams == nil) {
            let postParamsEncoded = postParams!.stringFromHttpParameters()
            //url = url + "?" + postParamsEncoded
            request.HTTPBody = postParamsEncoded.dataUsingEncoding(NSUTF8StringEncoding)
            headers["Content-Type"] = "application/x-www-form-urlencoded"
            request.HTTPMethod = "POST"
        } else if headers.indexForKey("Content-Type") != nil {
            headers["Content-Type"] = nil
        }
        
        request.HTTPMethod = "GET"
        request.addValue(referer, forHTTPHeaderField: "Referer")
        for (index, value) in headers {
            request.setValue(value, forHTTPHeaderField: index)
        }
        
        HTTPsendRequest(request, callback: callback)
    }
    
    func logout() {
        HTTPGet(httpSiteUrl + "/logout.aspx", referer: httpSiteUrl, postParams: nil) {
            (data: String, error: String?) -> Void in
            if error != nil {
                print(error)
            } else {
                //print(data)
            }
        }
    }
    
    func checkLogin() -> Bool {

        var page : String
        
        if !login.isEmpty {
            HTTPGet(httpSiteUrl, referer: httpSiteUrl, postParams: nil) {
                (data: String, error: String?) -> Void in
                if error != nil {
                    print("Can't read data")
                    return
                } else {
                    page = data
                }
            }
            
            let doc = Kanna.HTML(html: page, encoding: NSUTF8StringEncoding)
            let isLoggedIn = doc!.xpath("//a[@class=b-header__user-profile]").count
            
            if isLoggedIn == 0 {
                var loginResponse : String
                HTTPGet(httpSiteUrl + "/login.aspx", referer: httpSiteUrl, postParams: ["login": login, "passwd": password, "remember": "on"]){
                    (data: String, error: String?) -> Void in
                    if error != nil {
                        return
                    } else {
                        loginResponse = data
                    }
                }
                
                let doc = Kanna.HTML(html: loginResponse, encoding: NSUTF8StringEncoding)
                let isLoggedIn = doc!.xpath("//a[@class=b-header__user-profile]").count
                
                if isLoggedIn == 0 {
                    print("Check login and password")
                } else {
                    return true
                }
                
            } else {
                return true
            }
        }
        return false
    }
    
    
}
