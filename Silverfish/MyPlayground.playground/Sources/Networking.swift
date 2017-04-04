import UIKit

extension String {
    
    func stringByAddingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters as CharacterSet)
    }
    
}

extension Dictionary {
    
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).stringByAddingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = (value as! String).stringByAddingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameterArray.joined(separator: "&")
    }
    
}

let login = "max.ryazanov"
let password = "q3dm17"
let siteUrl = "fs.life"

var headers = [
    "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 9_3_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13E238 Safari/601.1",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "ru-RU,ru;q=0.9,en;q=0.8",
    "Accept-Charset": "utf-8, utf-16, *;q=0.1",
    "Accept-Encoding": "identity, *;q=0"
]

var httpSiteUrl: String {
get {
    return "https://" + siteUrl
}
}

func getFullUrl(url: String) -> String {
    var url : String = url
    if url.hasPrefix("//") {
        url = "https:" + url
    }
    
    if (url.range(of: "://") == nil) {
        url = httpSiteUrl + url
    }
    return url
}

func matchesForRegexInText(regex: String, text: String) -> [String] {
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

func htmlDecode(html : NSData) -> String {
    let decodedString = NSString(data: html as Data, encoding: String.Encoding.utf8.rawValue) as! String
    return decodedString
}

private func setCookies(response: URLResponse) {
    let cookies = HTTPCookieStorage.shared.cookies(for: response.url!)
    print(cookies!)
}

func HTTPsendRequest(request: NSMutableURLRequest, callback: @escaping (String, String?) -> Void) {
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration)
    let task = session.dataTask(with: request as URLRequest, completionHandler :
        {
            data, response, error in
            if error != nil {
                callback("", (error!.localizedDescription) as String)
            } else {
                callback(htmlDecode(html: data! as NSData), nil)
                //self.setCookies(response!)
            }
    })
    
    task.resume()
}

func HTTPGet(url: String, referer: String, postParams: Dictionary<String, AnyObject>?, callback: @escaping (String, String?) -> Void) {
    
    let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
    
    if postParams != nil {
        print("It is POST request")
        let postParamsEncoded = postParams!.stringFromHttpParameters()
        request.httpBody = postParamsEncoded.data(using: String.Encoding.utf8)
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        request.httpMethod = "POST"
    } else if headers.index(forKey: "Content-Type") != nil {
        print("It is GET request")
        //headers["Content-Type"] = nil
        headers.removeValue(forKey: "Content-Type")
        request.httpMethod = "GET"
    }
    
    request.addValue(referer, forHTTPHeaderField: "Referer")
    for (index, value) in headers {
        request.setValue(value, forHTTPHeaderField: index)
    }
    
    HTTPsendRequest(request: request, callback: callback)
}
