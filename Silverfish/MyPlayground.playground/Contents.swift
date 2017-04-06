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

let url = NSURL.init(string: "http://fs.life/video/films/?sort=trend")
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
        let doc = HTMLDocument.init(data: data!, contentTypeHeader: contentType! as String)
        //var popularMoviesArray = [Item]()
        
        let popularMovies = doc.nodes(matchingSelector: ".b-poster-tile   ")
        
        for element in popularMovies {
            //let item = Item()
            let linkNodes = element.nodes(matchingSelector: ".b-poster-tile__link")
            for link in linkNodes {
                let itemLink = link.attributes["href"]
                NSLog("%@", itemLink!)
            }
            
            let imageURLNodes = element.nodes(matchingSelector: ".b-poster-tile__image img")
            for image in imageURLNodes {
                let posterLink = image.attributes["src"]
                let itemPoster = posterLink
                NSLog("%@", itemPoster!)
            }
            
            //let titleNodes = element.search(withXPathQuery: "//span[@class='b-poster-tile__title-short']") as! [TFHppleElement]
            let titleNodes = element.nodes(matchingSelector: ".b-poster-tile__title-short")
            for title in titleNodes {
                let itemTitle = title.textContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                NSLog("%@", itemTitle)
            }
            
            //popularMoviesArray.append(item)
        }    }

//    let div: HTMLElement = home.firstNode(matchingSelector: ".repository-meta-content")!
//    let whitespace = NSCharacterSet.whitespacesAndNewlines as NSCharacterSet
//    NSLog("%@", div.textContent.trimmingCharacters(in: whitespace as CharacterSet))
    
} .resume()


