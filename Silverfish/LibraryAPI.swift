//
//  LibraryAPI.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 08.05.16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit
import HTMLReader

class LibraryAPI: NSObject {
    class var sharedInstance: LibraryAPI {
        struct Singleton {
            static let instance = LibraryAPI()
        }
        return Singleton.instance
    }
    
    fileprivate let persistencyManager: PersistencyManager
    fileprivate let httpClient: HTTPClient

    override init() {
        self.persistencyManager = PersistencyManager()
        self.httpClient = HTTPClient()
        
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.downloadImage(_:)), name: NSNotification.Name(rawValue: "DownloadImageNotification"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func getItems() -> [Item] {
        return persistencyManager.getItems()
    }
    
    func addItem(_ item: Item, index: Int) {
        persistencyManager.addItem(item, index: index)
    }
    
    func deleteItem(_ index: Int) {
        persistencyManager.deleteItemAtIndex(index)
    }
    
    func getMainPageItems() -> [[Item]] {
        return persistencyManager.getMainPageItems()
    }
    
    func addRowToMainPage(_ itemsArray: [Item], atIndex: Int) {
        persistencyManager.addRowToMainPage(itemsArray, atIndex: atIndex)
    }
    
    func loadData() {
        self.getPopularItems()
        self.getNewMovies()
        self.getNewTVShows()
        //        if isLogged {
        //            libAPI.getFavorites()
        //        }
    }
    
    func httpGET(_ url: String, referer: String!, postParams: Dictionary<String, String>?, callback: @escaping (Data?, URLResponse?, String?) -> Void) {
        httpClient.HTTPGet(url, referer: referer, postParams: postParams, callback: callback)
    }
    
//    func downloadImage(notification: NSNotification) {
//
//        let userInfo = notification.userInfo as! [String: AnyObject]
//        let imageView = userInfo["imageView"] as! UIImageView?
//        let coverUrl = "https:\(userInfo["coverUrl"] as! String)"
//        let filename = NSURL(string: coverUrl)
//        
//        if let imageViewUnWrapped = imageView {
//            imageViewUnWrapped.image = persistencyManager.getImage(filename!.lastPathComponent!)
//            if imageViewUnWrapped.image == nil {
//
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                    self.httpClient.HTTPGet(coverUrl, referer: nil, postParams: nil, callback: { (data, error) in
//                        let downloadedImage = UIImage(data: data!)
//                        
//                        dispatch_sync(dispatch_get_main_queue(), { () -> Void in
//                            imageViewUnWrapped.image = downloadedImage
//                            self.persistencyManager.saveImage(downloadedImage!, filename: filename!.lastPathComponent!)
//                        })
//                    })
//                })
//            }
//        }
//    }
    
    func downloadImage(_ notification: Notification) {
        
        let userInfo = (notification as NSNotification).userInfo as! [String: AnyObject]
        let imageView = userInfo["imageView"] as! UIImageView?
        let coverUrl = userInfo["coverUrl"] as! String
        
        if let imageViewUnWrapped = imageView {
            
            DispatchQueue.global().async(execute: { () -> Void in
                self.httpClient.getImage(coverUrl, callback: { (data, response, error) in
                    let downloadedImage = UIImage(data: data!)
                    
                    DispatchQueue.main.sync(execute: { () -> Void in
                        imageViewUnWrapped.image = downloadedImage
                    })
                })
            })
        }
    }
    
    func downloadImage(at URL: String, success: ((UIImage) -> ())? ) {
        DispatchQueue.global().async(execute: { () -> Void in
            self.httpClient.getImage(URL, callback: { (data, response, error) in
                let downloadedImage = UIImage(data: data!)
                defer {
                    if success != nil {
                        DispatchQueue.main.sync(execute: { () -> Void in
                            success!(downloadedImage!)
                        })
                    }
                }
            })
        })
        
    }
    
//    func getOMDBInfo(item: Item, title: String!) {
//        
//        let url = "https://www.omdbapi.com/?t=\(title)&r=json"
//        httpGET(url, referer: nil, postParams: nil) { (data, error) in
//            if error != nil {
//                print(">>> Error getting data: \(error)")
//            } else {
//                do {
//                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
//                    
//                    item.year = json["Year"] as? String
//                    item.actors = json["Actors"] as? String
//                    item.director = json["Director"] as? String
//                    item.genre = json["Genre"] as? String
//                    item.country = json["Country"] as? String
//                    item.itemPoster = json["Poster"] as? String
//                    
//                } catch {
//                    print("error serializing JSON: \(error)")
//                }
//            }
//        }
//    }
    
    func retrieveSearchResults(_ searchText: String, success: (([Item]) -> ())? ) {
        let encodedSearchQuery = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let parameters = "search.aspx?search=\(encodedSearchQuery)"
        let searchUrl = httpSiteUrl + "/" + parameters
        
        DispatchQueue.global().async { () -> Void in
            self.httpGET(searchUrl, referer: httpSiteUrl, postParams: nil) { (data, response, error) in
                var contentType: NSString? = nil
                if (response!.isKind(of: HTTPURLResponse.self)) {
                    let headers: NSDictionary = (response as! HTTPURLResponse).allHeaderFields as NSDictionary
                    contentType = headers.value(forKey: "Content-Type") as? NSString
                }
                if error != nil {
                    print(">>> Error getting data: \(String(describing: error))")
                } else {
                    var searchResuts = [Item]()
                    defer {
                        if success != nil {
                            DispatchQueue.main.sync(execute: { () -> Void in
                                success!(searchResuts)
                            })
                        }
                    }
                    
                    let doc = HTMLDocument.init(data: data!, contentTypeHeader: contentType! as String)
                    let results = doc.nodes(matchingSelector: "a[class='b-search-page__results-item  m-video']")
                    
                    for element in results {
                        let item = Item()
                        item.itemLink = element.attributes["href"]
                        
                        // TODO: Check item link for 404
                        // If so, do not add item to list.
                        
                        let posterUrl = (element.firstNode(matchingSelector: "img"))?.attributes["src"]
                        item.itemPoster = getBiggerThumbLink(posterUrl!, sizeIndex: "6")
                        item.itemTitle = (element.firstNode(matchingSelector: ".b-search-page__results-item-title"))?.textContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        item.genre = (element.firstNode(matchingSelector: "span[class='b-search-page__results-item-genres']"))?.textContent.capitalized
                        item.upVoteValue = (element.firstNode(matchingSelector: "span[class='b-search-page__results-item-rating-positive']"))?.textContent
                        item.downVoteValue = (element.firstNode(matchingSelector: "span[class='b-search-page__results-item-rating-negative']"))?.textContent
                        
                        searchResuts.append(item)
                    }
                }
            }
        }
    }
    
    func getMainItemsRow(at URL: String, success: (([Item]) -> ())? ) {
        DispatchQueue.global().async { () -> Void in
            self.httpGET(httpSiteUrl + URL, referer: httpSiteUrl, postParams: nil) { (data, response, error) in
                var contentType: NSString? = nil
                if (response!.isKind(of: HTTPURLResponse.self)) {
                    let headers: NSDictionary = (response as! HTTPURLResponse).allHeaderFields as NSDictionary
                    contentType = headers.value(forKey: "Content-Type") as? NSString
                }
                if error != nil {
                    print(error!)
                    return
                } else {
                    var resultsArray = [Item]()
                    defer {
                        if success != nil {
                            DispatchQueue.main.sync(execute: { () -> Void in
                                success!(resultsArray)
                            })
                        }
                    }
                    
                    let doc = HTMLDocument.init(data: data!, contentTypeHeader: contentType! as String)
                    let results = doc.nodes(matchingSelector: ".b-poster-tile   ")
                    
                    for element in results {
                        let item = Item()
                        let linkNodes = element.nodes(matchingSelector: ".b-poster-tile__link")
                        for link in linkNodes {
                            item.itemLink = link.attributes["href"]
                        }
                        
                        let imageURLNodes = element.nodes(matchingSelector: ".b-poster-tile__image img")
                        for image in imageURLNodes {
                            let posterLink = image.attributes["src"]
                            item.itemPoster = posterLink
                        }
                        
                        let titleNodes = element.nodes(matchingSelector: ".b-poster-tile__title-short")
                        for title in titleNodes {
                            item.itemTitle = title.textContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        }
                        
                        resultsArray.append(item)
                    }
                }
            }
        }
    }
    
    func getPopularItems() {
        DispatchQueue.global().async { () -> Void in
            self.httpGET(httpSiteUrl + "/video/films/?sort=popularity", referer: httpSiteUrl, postParams: nil) { (data, response, error) in
                var contentType: NSString? = nil
                if (response!.isKind(of: HTTPURLResponse.self)) {
                    let headers: NSDictionary = (response as! HTTPURLResponse).allHeaderFields as NSDictionary
                    contentType = headers.value(forKey: "Content-Type") as? NSString
                }
                if error != nil {
                    print(error!)
                    return
                } else {
                    let doc = HTMLDocument.init(data: data!, contentTypeHeader: contentType! as String)
                    var popularMoviesArray = [Item]()
                    
                    let popularMovies = doc.nodes(matchingSelector: ".b-poster-tile   ")
                    
                    for element in popularMovies {
                        let item = Item()
                        let linkNodes = element.nodes(matchingSelector: ".b-poster-tile__link")
                        for link in linkNodes {
                            item.itemLink = link.attributes["href"]
                        }
                        
                        let imageURLNodes = element.nodes(matchingSelector: ".b-poster-tile__image img")
                        for image in imageURLNodes {
                            let posterLink = image.attributes["src"]
                            item.itemPoster = posterLink
                        }
                        
                        let titleNodes = element.nodes(matchingSelector: ".b-poster-tile__title-short")
                        for title in titleNodes {
                            item.itemTitle = title.textContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        }
                        
                        popularMoviesArray.append(item)
                    }
                    
                    DispatchQueue.main.sync(execute: { () -> Void in
                        self.addRowToMainPage(popularMoviesArray, atIndex: 0)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "reload"), object: nil)
                    })
                }
            }
        }
    }
    
    func getNewMovies() {
        DispatchQueue.global().async { () -> Void in
            self.httpGET(httpSiteUrl + "/video/films/?sort=new", referer: httpSiteUrl, postParams: nil) { (data, response, error) in
                var contentType: NSString? = nil
                if (response!.isKind(of: HTTPURLResponse.self)) {
                    let headers: NSDictionary = (response as! HTTPURLResponse).allHeaderFields as NSDictionary
                    contentType = headers.value(forKey: "Content-Type") as? NSString
                }
                if error != nil {
                    print(error!)
                    return
                } else {
                    let doc = HTMLDocument.init(data: data!, contentTypeHeader: contentType! as String)
                    var newMoviesArray = [Item]()
                    
                    let newMovies = doc.nodes(matchingSelector: ".b-poster-tile   ")
                    
                    for element in newMovies {
                        let item = Item()
                        let linkNodes = element.nodes(matchingSelector: ".b-poster-tile__link")
                        for link in linkNodes {
                            item.itemLink = link.attributes["href"]
                        }
                        
                        let imageURLNodes = element.nodes(matchingSelector: ".b-poster-tile__image img")
                        for image in imageURLNodes {
                            item.itemPoster = image.attributes["src"]
                        }
                        
                        let titleNodes = element.nodes(matchingSelector: ".b-poster-tile__title-short")
                        for title in titleNodes {
                            item.itemTitle = title.textContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        }
                        
                        newMoviesArray.append(item)
                    }
                    
                    DispatchQueue.main.sync(execute: { () -> Void in
                        self.addRowToMainPage(newMoviesArray, atIndex: 1)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "reload"), object: nil)
                    })
                }
            }
        }
    }
    
    func getNewTVShows() {
        DispatchQueue.global().async { () -> Void in
            self.httpGET(httpSiteUrl + "/video/serials/?sort=new", referer: httpSiteUrl, postParams: nil) { (data, response, error) in
                var contentType: NSString? = nil
                if (response!.isKind(of: HTTPURLResponse.self)) {
                    let headers: NSDictionary = (response as! HTTPURLResponse).allHeaderFields as NSDictionary
                    contentType = headers.value(forKey: "Content-Type") as? NSString
                }
                if error != nil {
                    print(error!)
                    return
                } else {
                    let doc = HTMLDocument.init(data: data!, contentTypeHeader: contentType! as String)
                    var newTVShowsArray = [Item]()
                    
                    let newTVShows = doc.nodes(matchingSelector: ".b-poster-tile   ")
                    
                    for element in newTVShows {
                        let item = Item()
                        let linkNodes = element.nodes(matchingSelector: ".b-poster-tile__link")
                        for link in linkNodes {
                            item.itemLink = link.attributes["href"]
                        }
                        
                        let imageURLNodes = element.nodes(matchingSelector: ".b-poster-tile__image img")
                        for image in imageURLNodes {
                            item.itemPoster = image.attributes["src"]
                        }
                        
                        let titleNodes = element.nodes(matchingSelector: ".b-poster-tile__title-short")
                        for title in titleNodes {
                            item.itemTitle = title.textContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        }
                        
                        newTVShowsArray.append(item)
                    }
                    
                    DispatchQueue.main.sync(execute: { () -> Void in
                        self.addRowToMainPage(newTVShowsArray, atIndex: 2)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "reload"), object: nil)
                    })
                }
            }
        }
    }
    
//    func getFavorites() {
//        DispatchQueue.global().async { () -> Void in
//            self.httpGET(httpSiteUrl + "/myfavourites.aspx?page=inprocess", referer: httpSiteUrl, postParams: nil) { (data, response, error) in
//                if error != nil {
//                    print(error!)
//                    return
//                } else {
//                    if let doc = TFHpple(htmlData: data) {
//                        DispatchQueue.main.sync(execute: { () -> Void in
//                            var favoritesArray = [Item]()
//                            
//                            var XPathQuery = "//div[@class='b-category m-theme-video ']"
//                            guard let categoryElements = doc.search(withXPathQuery: XPathQuery) as? [TFHppleElement] else { return }
//                            for categoryElement in categoryElements {
//                                let item = Item()
//                                
//                                XPathQuery = "//span[@class='section-title']/b"
//                                item.categoryName = (categoryElement.search(withXPathQuery: XPathQuery).last as? TFHppleElement)?.text()
//                                
//                                XPathQuery = "//b[@class='subject-link']/span"
//                                item.itemTitle = (categoryElement.search(withXPathQuery: XPathQuery).last as? TFHppleElement)?.text()
//                                
//                                XPathQuery = "//a[@class='b-poster-thin m-video ']/@href"
//                                item.itemLink = (categoryElement.search(withXPathQuery: XPathQuery).last as? TFHppleElement)?.text()
//                                
//                                XPathQuery = "//a[@class='b-poster-thin m-video ']/@style"
//                                let wrappedString = (categoryElement.search(withXPathQuery: XPathQuery).last as? TFHppleElement)?.text()
//                                
//                                item.itemPoster = (matchesForRegexInText("(?<=\')(.*)(?=\')", text: wrappedString!)).first
//                                
//                                favoritesArray.append(item)
//                            }
//                        })
//                    }
//                }
//            }
//        }
//    }
    
    func getItemDetails(_ item: Item) {
        DispatchQueue.global().async { () -> Void in
            self.httpGET(httpSiteUrl + item.itemLink! + "?json", referer: httpSiteUrl, postParams: nil) { (data, response, error) in
                if error != nil {
                    print(error!)
                    return
                } else {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary
                        item.name = json?.value(forKey: "title") as? String
                        item.altName = json?.value(forKey: "title_origin") as? String
                        item.itemDescription = json?.value(forKey: "description") as? String
                        
                        item.genre = (json?.value(forKey: "genre") as? String)?.replacingOccurrences(of: ",", with: ", ")
                        item.country = (json?.value(forKey: "made_in") as? String)?.replacingOccurrences(of: ",", with: ", ")
                        item.director = (json?.value(forKey: "director") as? String)?.replacingOccurrences(of: ",", with: ", ")
                        item.actors = (json?.value(forKey: "cast") as? String)?.replacingOccurrences(of: ",", with: ", ")
                        
                        //item.year = json?.value(forKey: "year") as? String
                        
                        if json?.value(forKey: "show_end") != nil {
                            item.year = (json?.value(forKey: "show_start") as! String) + " - " + (json?.value(forKey: "show_end") as! String)
                        } else {
                            item.year = (json?.value(forKey: "year") as! String)
                        }
                        
                    } catch let error {
                        print(error.localizedDescription)
                    }
                    
                    
                    item.hasDetails = true
                }
            }
        }
    }
    
//    func getItemDetails(_ item: Item) {
//        DispatchQueue.global().async { () -> Void in
//            self.httpGET(httpSiteUrl + item.itemLink!, referer: httpSiteUrl, postParams: nil) { (data, response, error) in
//                var contentType: NSString? = nil
//                if (response!.isKind(of: HTTPURLResponse.self)) {
//                    let headers: NSDictionary = (response as! HTTPURLResponse).allHeaderFields as NSDictionary
//                    contentType = headers.value(forKey: "Content-Type") as? NSString
//                }
//                if error != nil {
//                    print(error!)
//                    return
//                } else {
//                    let doc = HTMLDocument.init(data: data!, contentTypeHeader: contentType! as String)
//
//                    item.name = (doc.firstNode(matchingSelector: ".b-tab-item__title-inner span")?.textContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
//
//                    if let altName = doc.firstNode(matchingSelector: "div[itemprop='alternativeHeadline']") {
//                        item.altName = altName.textContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//                    }
//
//                    let itemInfo = doc.firstNode(matchingSelector: "div[class='item-info']")
//
//                    if let yearsNodes = itemInfo?.nodes(matchingSelector: "tbody tr:nth-child(2) td:nth-child(2) a span") {
//                        var years = [String]()
//                        for yearNode in yearsNodes {
//                            years.append(yearNode.textContent)
//                        }
//
//                        if yearsNodes.count == 1 {
//                            if itemInfo?.firstNode(matchingSelector: "span[class='tag show-continues'] span") != nil {
//                                years.append("...")
//                            }
//                        }
//
//                        item.year = years.joined(separator: "-")
//                    }
//
//                    if let genreNodes = itemInfo?.nodes(matchingSelector: "span[itemprop='genre'] a span") {
//                        var genres = [String]()
//                        for node in genreNodes {
//                            genres.append(node.textContent)
//                        }
//                        item.genre = (genres.joined(separator: ", ")).capitalized
//                    }
//
//                    var selector = String()
//                    var countries = [String]()
//
//                    if item.itemLink!.contains("serials") {
//                        selector = "tbody tr:nth-child(4) td:nth-child(2) a span"
//                    } else {
//                        selector = "tbody tr:nth-child(3) td:nth-child(2) a span"
//                    }
//                    let countryNodes = itemInfo?.nodes(matchingSelector: selector)
//
//                    for country in countryNodes! {
//                        if country.textContent.isEmpty {
//                            continue
//                        }
//                        countries.append(country.textContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
//                    }
//                    item.country = countries.joined(separator: ", ")
//
//                    if let directorNodes = itemInfo?.nodes(matchingSelector: "span[itemprop='director'] a span") {
//                        var directors = [String]()
//                        for director in directorNodes {
//                            directors.append(director.textContent)
//                        }
//                        item.director = directors.joined(separator: ", ")
//                    }
//
//                    if let actorNodes = itemInfo?.nodes(matchingSelector: "span[itemprop='actor'] a span") {
//                        var actors = [String]()
//                        for actor in actorNodes {
//                            actors.append(actor.textContent)
//                        }
//                        item.actors = actors.joined(separator: ", ")
//                    }
//
//                    if let rating = itemInfo?.firstNode(matchingSelector: "meta[itemprop='ratingValue']") {
//                        item.ratingValue = Float(rating.attributes["content"]!)!/10
//                    } else {
//                        item.ratingValue = 0.0
//                    }
//
//                    if let upVoteValue = itemInfo?.firstNode(matchingSelector: "div[class*='vote-value_type_yes')]") {
//                        item.upVoteValue = upVoteValue.textContent
//                    } else {
//                        item.upVoteValue = ""
//                    }
//
//                    if let downVoteValue = itemInfo?.firstNode(matchingSelector: "div[class*='vote-value_type_no')]") {
//                        item.downVoteValue = downVoteValue.textContent
//                    } else {
//                        item.downVoteValue = ""
//                    }
//
//                    let thumbs = doc.nodes(matchingSelector: "a[class='images-show'][style]")
//                    if !(thumbs.isEmpty) {
//                        item.thumbsUrl = []
//                        for thumb in thumbs {
//                            var thumbLink = thumb.attributes["style"]
//                            thumbLink = thumbLink?.components(separatedBy: "(").last!
//                            thumbLink = thumbLink?.components(separatedBy: ")").first!
//                            let biggerThumbLink = getBiggerThumbLink(thumbLink!, sizeIndex: "2")
//                            item.thumbsUrl!.append(biggerThumbLink)
//                        }
//                    } else {
//                        item.thumbsUrl = []
//                        let biggerThumbLink = getBiggerThumbLink(item.itemPoster!, sizeIndex: "1")
//                        item.thumbsUrl!.append(biggerThumbLink)
//                    }
//
//                    let similarMovies = doc.nodes(matchingSelector: "div[class='b-poster-new ']")
//                    item.similarItems = []
//                    for movie in similarMovies {
//                        let similarItem = Item()
//                        similarItem.itemLink = (movie.firstNode(matchingSelector: "a"))?.attributes["href"]
//
//                        similarItem.itemTitle = (movie.firstNode(matchingSelector: "span[class='m-poster-new__full_title']"))?.textContent
//
//                        var posterLink = (movie.firstNode(matchingSelector: "span[class*='image-poster']"))?.attributes["style"]
//                        posterLink = posterLink?.components(separatedBy: "('").last!
//                        posterLink = posterLink?.components(separatedBy: "')").first!
//                        similarItem.itemPoster = getBiggerThumbLink(posterLink!, sizeIndex: "6")
//
//                        item.similarItems!.append(similarItem)
//                    }
//
//                    if let itemDescription = doc.firstNode(matchingSelector: "div[class='b-tab-item__description'] span p") {
//                        item.itemDescription = itemDescription.textContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//                    } else if let itemDescription = doc.firstNode(matchingSelector: "div[class='b-tab-item__description'] p") {
//                        item.itemDescription = itemDescription.textContent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//                    }
//                    
//                    
//                    
//                    item.hasDetails = true
//                }
//            }
//        }
//    }
    
//    func readDirectory(_ item: Item) {
//        let folderUrl = getFullUrl(item.itemLink!)
//        
//        let getUrl = "\(folderUrl)?ajax&folder=\(item.folderId)"
//        
//        httpGET(getUrl, referer: httpSiteUrl, postParams: nil) { (data, response, error) in
//            var contentType: NSString? = nil
//            if (response!.isKind(of: HTTPURLResponse.self)) {
//                let headers: NSDictionary = (response as! HTTPURLResponse).allHeaderFields as NSDictionary
//                contentType = headers.value(forKey: "Content-Type") as? NSString
//            }
//            if error != nil {
//                print(error!)
//                return
//            } else {
//                let doc = HTMLDocument.init(data: data!, contentTypeHeader: contentType! as String)
//                let folderList: HTMLElement?
//                
//                if item.folderId == "0" {
//                    //                    if let blockedContent = doc.firstNode(matchingSelector: "div[id='file-block-text']") {
//                    //                        // Show message "Blocked Content"
//                    //                    }
//                }
//                
//                if let filelist = doc.firstNode(matchingSelector: "ul[class='filelist m-current']") {                    
//                    let files = filelist.nodes(matchingSelector: "a[class*='video-hdrip']")
//                    for file in files {
//                        let newFile = File()
//                        // get links & sizes
//                        newFile.title = file.firstNode(matchingSelector: "span[class*='filename-text']")?.textContent
//                        newFile.link = file.firstNode(matchingSelector: "a[class*='download']")?.attributes["href"]
//                        newFile.info = file.firstNode(matchingSelector: "span[class*='size']")?.textContent
//                        item.fileList?.append(newFile)
//                    }
//                    
//                } else {
//                    folderList = doc.firstNode(matchingSelector: "*[class*='filelist')]")
//                    // get folderId
//                    for folder in folderList!.childElementNodes {
//                        // Get folder
//                        var identifier: String!
//                        identifier = (folder as AnyObject).firstNode(matchingSelector: "a")?.attributes["name"]
//                        identifier = identifier.replacingOccurrences(of: "fl", with: "")
//                        item.folderId = identifier;
//                    }
//                }
//                
//                
//                //                for folder in folderList!.childElementNodes {
//                //                    guard let classValue = folder.attributes["class"] else { continue }
//                //                    if classValue.hasPrefix("folder") {
//                //
//                //                        // only root folders contains 'header' tag
//                //                        let isRootFolder = folder.numberOfChildren > 0
//                //
//                //                        // identifier
//                //                        var identifier: String!
//                //                        identifier = (folder as AnyObject).firstNode(matchingSelector: "a")?.attributes["name"]
//                //                        identifier = identifier.replacingOccurrences(of: "fl", with: "")
//                //                        item.folderId = identifier;
//                //
//                //
//                //                        // quality
//                //                        if (isRootFolder) {
//                //                            folder.videoQuality = VideoQuality.Undefined
//                //                        } else {
//                //                            let qualityString = (folder.searchWithXPathQuery("//div[1]").last as! TFHppleElement).attributes["class"] as! String
//                //                            if ((qualityString as NSString).rangeOfString("m-hd").location != NSNotFound) {
//                //                                folder.videoQuality = VideoQuality.HD
//                //                            } else if ((qualityString as NSString).rangeOfString("m-sd").location != NSNotFound) {
//                //                                folder.videoQuality = VideoQuality.SD
//                //                            } else {
//                //                                folder.videoQuality = VideoQuality.Undefined
//                //                            }
//                //                        }
//                //
//                //                        // language
//                //                        if (isRootFolder) {
//                //                            folder.language = VideoLanguage.Undefined
//                //                        } else {
//                //                            let languageString = (folder.searchWithXPathQuery("//div[2]/a[1]").last as! TFHppleElement).attributes["class"] as! String
//                //                            if ((languageString as NSString).rangeOfString("m-en").location != NSNotFound) {
//                //                                folder.language = VideoLanguage.EN
//                //                            } else if ((languageString as NSString).rangeOfString("m-ru").location != NSNotFound) {
//                //                                folder.language = VideoLanguage.RU
//                //                            } else if ((languageString as NSString).rangeOfString("m-ua").location != NSNotFound) {
//                //                                folder.language = VideoLanguage.UA
//                //                            } else {
//                //                                folder.language = VideoLanguage.Undefined
//                //                            }
//                //                        }
//                //
//                //                        folder.details = (folder.childrenWithClassName("material-details").first as! TFHppleElement).text()
//                //                        folder.size = (folder.childrenWithClassName("material-details").last as! TFHppleElement).text()
//                //                        folder.dateString = (folder.childrenWithClassName("material-date").last as! TFHppleElement).text()
//                //
//                //                        items.append(folder)
//                //                    } else if (classValue as NSString).range(of: "file").location != NSNotFound {
//                //                        let file = File()
//                //
//                //                        file.name = (folder.searchWithXPathQuery("//span/span").last as! TFHppleElement).text()
//                //                        file.size = (folder.searchWithXPathQuery("//a/span").last as! TFHppleElement).text()
//                //
//                //                        let typeString = folder.attributes["class"] as! String
//                //                        if ((typeString as NSString).rangeOfString("m-file-new_type_video").location != NSNotFound) {
//                //                            file.type = FileType.Video
//                //                        } else if ((typeString as NSString).rangeOfString("m-file-new_type_audio").location != NSNotFound) {
//                //                            file.type = FileType.Audio
//                //                        } else {
//                //                            file.type = FileType.Undefined
//                //                        }
//                //
//                //                        let pathComponent = (folder.searchWithXPathQuery("//a").last as! TFHppleElement)["href"] as! String
//                //                        let fileURL = NSURL(scheme: "http", host: "brb.to", path: pathComponent)
//                //                        file.URL = fileURL
//                //
//                //                        items.append(file)
//                //                    }
//                //                }
//            }
//        }
//    }
}
