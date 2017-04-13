import PlaygroundSupport
import UIKit
import HTMLReader

PlaygroundPage.current.needsIndefiniteExecution = true

let url = NSURL.init(string: "http://fs.life/video/serials/iKf0JMsvwnbkK9UkPDzHm9-smertelnoje-oruzhije.html?json")
let session = URLSession.shared
var request = NSMutableURLRequest(url: url! as URL)
//request.setValue("application/json", forHTTPHeaderField: "Content-Type")
URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)

session.dataTask(with: request as URLRequest) { (data, response, error) in
    var contentType: NSString? = nil
    if (response!.isKind(of: HTTPURLResponse.self)) {
        let headers: NSDictionary = (response as! HTTPURLResponse).allHeaderFields as NSDictionary
        contentType = headers.value(forKey: "Content-Type") as? NSString
    }
    if (error != nil) {
        print(error!)
        return
    } else {
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary
            
            var cast = (json?.value(forKey: "cast") as! String).replacingOccurrences(of: ",", with: ", ")
            
//            for (key, value) in json! {
//                print("\(key): \(value)" )
//            }
//            var cast = ((json as AnyObject).value(forKey: "cast") as! String).replacingOccurrences(of: ",", with: ", ")
//            print(cast)
            
        } catch let error {
            print(error.localizedDescription)
        }

    }
    
} .resume()


