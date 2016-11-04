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

func getFullUrl(_ url: String) -> String {
    var url : String = url
    if url.hasPrefix("//") {
        url = "https:" + url
    }
    
    if (url.range(of: "://") == nil) {
        url = httpSiteUrl + url
    }
    return url
}

func matchesForRegexInText(_ regex: String, text: String) -> [String] {
    var result = [String]()
    do {
        let regex = try NSRegularExpression(pattern: regex, options: [])
        let nsString = text as NSString
        if let match = regex.firstMatch(in: text, options: [], range: NSMakeRange(0, nsString.length)) {
            for i in 1..<match.numberOfRanges {
                result.append(nsString.substring(with: match.rangeAt(i)))
            }
        }
    } catch let error as NSError {
        print("invalid regex: \(error.localizedDescription)")
    }
    return result
}

func getBiggerThumbLink(_ text: String, sizeIndex: String!) -> String {
    let nsString = NSMutableString(string: text)
    do {
        let regex = try NSRegularExpression(pattern: "([0-9]+)/([0-9]+)/([0-9]+)/([0-9]+)/([0-9]+).jpg", options: [])
        regex.replaceMatches(in: nsString, options: [], range: NSMakeRange(0, nsString.length), withTemplate: "$1/$2/$3/\(sizeIndex!)/$5\\.jpg")
        
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
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
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
        
        return parameterArray.joined(separator: "&")
    }
    
}

extension UIImageView {
    func downloadedFrom(_ link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: getFullUrl(link)) else { return }
        contentMode = .scaleAspectFill
        // Request
        let request = NSMutableURLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.httpShouldHandleCookies = false
        request.httpShouldUsePipelining = true
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        //Session
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse , httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType , mimeType.hasPrefix("image"),
                let data = data , error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.sync(execute: { () -> Void in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.image = image
            })
            }) .resume()
    }
}
