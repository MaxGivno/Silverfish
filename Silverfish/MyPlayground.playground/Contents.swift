import PlaygroundSupport
import UIKit
import HTMLReader

PlaygroundPage.current.needsIndefiniteExecution = true

var headers = [
    "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Mobile/14E277 Safari Line/7.1.3",
    "Accept": "text/html,application/xhtml+xml,application/json,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "ru-RU,ru;q=0.9,en;q=0.8",
    "Accept-Charset": "utf-8, utf-16, *;q=0.1",
    "Accept-Encoding": "identity, *;q=0"
]

let host = "http://fs.life"
let itemId = "4oJJrbddVc5DG2Rh8Qhmpz"
//let url = "\(host)/jsfilemanager.aspx?f=files_list&item_id=\(itemId)&id=false&u="
//let url = URL(string: "\(host)/jsitem/i\(itemId)/status.js")
//let referer = "\(host)/materials/edit/i\(itemId)?win=files"


//let url = NSURL.init(string: "http://fs.life/video/serials/iKf0JMsvwnbkK9UkPDzHm9-smertelnoje-oruzhije.html?json")
//let session = URLSession.shared
//var request = NSMutableURLRequest(url: url!)
////request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
//
//session.dataTask(with: request as URLRequest) { (data, response, error) in
//    var contentType: NSString? = nil
//    if (response!.isKind(of: HTTPURLResponse.self)) {
//        let headers: NSDictionary = (response as! HTTPURLResponse).allHeaderFields as NSDictionary
//        contentType = headers.value(forKey: "Content-Type") as? NSString
//    }
//    if (error != nil) {
//        print(error!)
//        return
//    } else {
//        do {
//            let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary
//            
//            //var cast = (json?.value(forKey: "cast") as! String).replacingOccurrences(of: ",", with: ", ")
//            
////            for (key, value) in json! {
////                print("\(key): \(value)" )
////            }
////            var cast = ((json as AnyObject).value(forKey: "cast") as! String).replacingOccurrences(of: ",", with: ", ")
////            print(cast)
//            
//        } catch let error {
//            print(error.localizedDescription)
//        }
//
//    }
//    
//} .resume()

//let postParams = ["login": "login", "passwd": "password", "remember": "on"]
//
//var components = URLComponents()
////let cs = CharacterSet.urlFragmentAllowed
//let cs = CharacterSet.urlQueryAllowed
//components.scheme = "http"
//components.host = "fs.life"
//components.path = "/login.aspx"
//components.query = postParams.map { (key, value) -> String in
//    key.addingPercentEncoding(withAllowedCharacters: cs)! + "=" + value.addingPercentEncoding(withAllowedCharacters: cs)!
//}.joined(separator: "&")
////components.percentEncodedFragment = postParams.map { (key, value) -> String in
////    key.addingPercentEncoding(withAllowedCharacters: cs)! + "=" + value.addingPercentEncoding(withAllowedCharacters: cs)!
////}.joined(separator: "&")
//print(components.query!)

let string = [["log":["enabled":true],"playerEventStats":["url":"/viewstatus.aspx?f=set_file_status"],"playerCounterStats":nil]]

let data = (string as NSDictionary).data(using: .utf8)



//JSONSerialization.jsonObject(with: string, options: JSONSerialization.ReadingOptions.mutableContainers)








