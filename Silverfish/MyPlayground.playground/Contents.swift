import PlaygroundSupport
import UIKit
import HTMLReader

PlaygroundPage.current.needsIndefiniteExecution = true

//let row = [["title": "Popular","url": "/video/films/?sort=trend"],
//           ["title": "Recently Added Movies","url": "/video/films/?sort=new"],
//           ["title": "Recently Added TV Shows","url": "/video/serials/?sort=new"]]
//
//row[2]["title"]

//let markup: NSString = "<p><b>Ahoy there sailor!</b></p>"
//let document: HTMLDocument = HTMLDocument(string: markup as String)

//NSLog("%@", document.firstNode(matchingSelector: "b")!.textContent)

//let b: HTMLElement = document.firstNode(matchingSelector: "b")!
//let children: NSMutableOrderedSet = b.parent!.mutableChildren
//let wrapper: HTMLElement = HTMLElement.init(tagName: "div", attributes: ["class": "special"])
//
//children.insert(wrapper, at: children.index(of: b))
//b.parent = wrapper

//NSLog("%@", document.rootElement!.serializedFragment)

let url = NSURL.init(string: "http://fs.life")
let session = URLSession.shared
var request = URLRequest(url: url! as URL)
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
        let home: HTMLDocument = HTMLDocument.init(data: data!, contentTypeHeader: contentType as String?)
        //let div: HTMLElement = home.firstNode(matchingSelector: ".b-poster-new__image-poster")!
        let div = home.nodes(matchingSelector: ".b-poster-new__image-poster")
        let whitespace = NSCharacterSet.whitespacesAndNewlines as NSCharacterSet
        //let imageUrl = div.attributes.index(forKey: "style")
        //NSLog("%@", div.textContent.trimmingCharacters(in: whitespace as CharacterSet))
        //NSLog("%@", imageUrl as Any)
    }

//    let div: HTMLElement = home.firstNode(matchingSelector: ".repository-meta-content")!
//    let whitespace = NSCharacterSet.whitespacesAndNewlines as NSCharacterSet
//    NSLog("%@", div.textContent.trimmingCharacters(in: whitespace as CharacterSet))
    
} .resume()
