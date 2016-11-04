//
//  Extensions.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 07.05.16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

internal var siteUrl = "fs.to"
internal var httpSiteUrl: String {
    get {
        return "https://" + siteUrl
    }
}

func getFullUrl(url: String) -> String {
    var url : String = url
    
    if url.hasPrefix("http:") {
        url = String(url.replaceRange(url.rangeOfString("http:")!, with: "https:"))
    }
    
    if url.hasPrefix("//") {
        url = "https:" + url
    }
    
    if (url.rangeOfString("://") == nil) {
        url = httpSiteUrl + url
    }
    return url
}

func matchesForRegexInText(regex: String, text: String) -> [String] {
    var result = [String]()
    do {
        let regex = try NSRegularExpression(pattern: regex, options: [])
        let nsString = text as NSString
        if let match = regex.firstMatchInString(text, options: [], range: NSMakeRange(0, nsString.length)) {
            for i in 1..<match.numberOfRanges {
                result.append(nsString.substringWithRange(match.rangeAtIndex(i)))
            }
        }
    } catch let error as NSError {
        print("invalid regex: \(error.localizedDescription)")
    }
    return result
}

func getBiggerThumbLink(text: String, sizeIndex: String!) -> String {
    let nsString = NSMutableString(string: text)
    do {
        let regex = try NSRegularExpression(pattern: "([0-9]+)/([0-9]+)/([0-9]+)/([0-9]+)/([0-9]+).jpg", options: [])
        regex.replaceMatchesInString(nsString, options: [], range: NSMakeRange(0, nsString.length), withTemplate: "$1/$2/$3/\(sizeIndex)/$5\\.jpg")
        
    } catch let error as NSError {
        print("invalid regex: \(error.localizedDescription)")
    }
    return nsString as String
}

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

extension UIImageView {
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .ScaleAspectFit) {
        guard let url = NSURL(string: getFullUrl(link)) else { return }
        contentMode = .ScaleAspectFill
        // Request
        let request = NSMutableURLRequest(URL: url)
        request.cachePolicy = .ReturnCacheDataElseLoad
        request.HTTPShouldHandleCookies = false
        request.HTTPShouldUsePipelining = true
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        //Session
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        session.dataTaskWithRequest(request) { (data, response, error) in
            guard
                let httpURLResponse = response as? NSHTTPURLResponse where httpURLResponse.statusCode == 200,
                let mimeType = response?.MIMEType where mimeType.hasPrefix("image"),
                let data = data where error == nil,
                let image = UIImage(data: data)
                else { return }
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.image = image
            })
            }.resume()
    }
}
