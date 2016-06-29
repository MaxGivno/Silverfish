import UIKit

extension String {
    
    func stringByAddingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        
        return self.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)
    }
    
}

extension Dictionary {
    
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).stringByAddingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = (value as! String).stringByAddingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameterArray.joinWithSeparator("&")
    }
    
}

let login = "max.ryazanov"
let password = "q3dm17"
let siteUrl = "fs.to"

var headers = [
    "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 9_3_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13E238 Safari/601.1",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "ru-RU,ru;q=0.9,en;q=0.8",
    "Accept-Charset": "utf-8, utf-16, *;q=0.1",
    "Accept-Encoding": "identity, *;q=0"
]

var httpSiteUrl: String {
get {
    return "http://" + siteUrl
}
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

func htmlDecode(html : NSData) -> String {
    let decodedString = NSString(data: html, encoding: NSUTF8StringEncoding) as! String
    return decodedString
}

private func setCookies(response: NSURLResponse) {
    let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(response.URL!)
    print(cookies)
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
                callback(htmlDecode(data!), nil)
                //self.setCookies(response!)
            }
    })
    
    task.resume()
}

func HTTPGet(url: String, referer: String, postParams: Dictionary<String, AnyObject>?, callback: (String, String?) -> Void) {
    
    let request = NSMutableURLRequest(URL: NSURL(string: url)!)
    
    if postParams != nil {
        print("It is POST request")
        let postParamsEncoded = postParams!.stringFromHttpParameters()
        request.HTTPBody = postParamsEncoded.dataUsingEncoding(NSUTF8StringEncoding)
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        request.HTTPMethod = "POST"
    } else if headers.indexForKey("Content-Type") != nil {
        print("It is GET request")
        //headers["Content-Type"] = nil
        headers.removeValueForKey("Content-Type")
        request.HTTPMethod = "GET"
    }
    
    request.addValue(referer, forHTTPHeaderField: "Referer")
    for (index, value) in headers {
        request.setValue(value, forHTTPHeaderField: index)
    }
    
    HTTPsendRequest(request, callback: callback)
}