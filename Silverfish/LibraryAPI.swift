//
//  LibraryAPI.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 08.05.16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class LibraryAPI: NSObject {
    class var sharedInstance: LibraryAPI {
        
        struct Singleton {
            static let instance = LibraryAPI()
        }
        
        return Singleton.instance
    }
    
    fileprivate let persistencyManager: PersistencyManager
    fileprivate let httpClient: HTTPClient
    //private var mainPageItems = [String : [Item]]()

    fileprivate let isOnline: Bool

    override init() {
        persistencyManager = PersistencyManager()
        httpClient = HTTPClient()
        isOnline = false
        
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
    
    func httpGET(_ url: String, referer: String!, postParams: Dictionary<String, String>?, callback: @escaping (Data?, String?) -> Void) {
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
                self.httpClient.getImage(coverUrl, callback: { (data, error) in
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
            self.httpClient.getImage(URL, callback: { (data, error) in
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
            self.httpGET(searchUrl, referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(">>> Error getting data: \(error)")
                } else {
                    var searchResuts = [Item]()
                    defer {
                        if success != nil {
                            DispatchQueue.main.sync(execute: { () -> Void in
                                success!(searchResuts)
                            })
                        }
                    }
                    
                    let doc = TFHpple(htmlData: data)
                    let results = doc?.search(withXPathQuery: "//a[@class='b-search-page__results-item  m-video']") as! [TFHppleElement]
                    
                    for element in results {
                        let item = Item()
                        item.itemLink = element.object(forKey: "href")
                        
                        // TODO: Check item link for 404
                        // If so, do not add item to list.
                        
                        let posterUrl = (element.search(withXPathQuery: "//img/@src").last as? TFHppleElement)?.text()
                        item.itemPoster = getBiggerThumbLink(posterUrl!, sizeIndex: "6")
                        
                        item.itemTitle = (element.search(withXPathQuery: "//@title").last as? TFHppleElement)?.text()
                        
                        item.genre = (element.search(withXPathQuery: "//span[@class='b-search-page__results-item-genres']").first as? TFHppleElement)?.text().capitalized
                        item.upVoteValue = (element.search(withXPathQuery: "//span[@class='b-search-page__results-item-rating-positive']").first as? TFHppleElement)?.text()
                        item.downVoteValue = (element.search(withXPathQuery: "//span[@class='b-search-page__results-item-rating-negative']").first as? TFHppleElement)?.text()
                        
                        //item.itemDescription = (element.searchWithXPathQuery("//span[@class='b-search-page__results-item-description']").last as? TFHppleElement)?.text().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        
                        searchResuts.append(item)
                    }
                }
            }
        }
    }
    
    func getMainItemsRow(at URL: String, success: (([Item]) -> ())? ) {
        DispatchQueue.global().async { () -> Void in
            self.httpGET(httpSiteUrl + URL, referer: httpSiteUrl, postParams: nil) { (data, error) in
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
                    
                    let doc = TFHpple(htmlData: data)
                    let results = doc?.search(withXPathQuery: "//div[@class='b-poster-tile   ']") as! [TFHppleElement]
                    
                    for element in results {
                        let item = Item()
                        let linkNodes = element.search(withXPathQuery: "//a[@class='b-poster-tile__link']") as! [TFHppleElement]
                        for link in linkNodes {
                            item.itemLink = link.object(forKey: "href")
                        }
                        
                        let imageURLNodes = element.search(withXPathQuery: "//span[@class='b-poster-tile__image']/img") as! [TFHppleElement]
                        for image in imageURLNodes {
                            let posterLink = image.object(forKey: "src")
                            item.itemPoster = posterLink
                        }
                        
                        let titleNodes = element.search(withXPathQuery: "//span[@class='b-poster-tile__title-short']") as! [TFHppleElement]
                        for title in titleNodes {
                            item.itemTitle = title.text().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        }
                        
                        //self.getItemDetails(item)
                        
                        resultsArray.append(item)
                    }
                }
            }
        }
    }
    
    func getPopularItems() {
        DispatchQueue.global().async { () -> Void in
            self.httpGET(httpSiteUrl + "/video/films/?sort=trend", referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error!)
                    return
                } else {
                    let doc = TFHpple(htmlData: data)
                    var popularMoviesArray = [Item]()
                    
                    let popularMovies = doc?.search(withXPathQuery: "//div[@class='b-poster-tile   ']") as! [TFHppleElement]
                    
                    for element in popularMovies {
                        let item = Item()
                        let linkNodes = element.search(withXPathQuery: "//a[@class='b-poster-tile__link']") as! [TFHppleElement]
                        for link in linkNodes {
                            item.itemLink = link.object(forKey: "href")
                        }
                        
                        let imageURLNodes = element.search(withXPathQuery: "//span[@class='b-poster-tile__image']/img") as! [TFHppleElement]
                        for image in imageURLNodes {
                            let posterLink = image.object(forKey: "src")
                            item.itemPoster = posterLink
                        }
                        
                        let titleNodes = element.search(withXPathQuery: "//span[@class='b-poster-tile__title-short']") as! [TFHppleElement]
                        for title in titleNodes {
                            item.itemTitle = title.text().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
            self.httpGET(httpSiteUrl + "/video/films/?sort=new", referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error!)
                    return
                } else {
                    let doc = TFHpple(htmlData: data)
                    var newMoviesArray = [Item]()
                    
                    let newMovies = doc?.search(withXPathQuery: "//div[@class='b-poster-tile   ']") as! [TFHppleElement]
                    
                    for element in newMovies {
                        let item = Item()
                        let linkNodes = element.search(withXPathQuery: "//a[@class='b-poster-tile__link']") as! [TFHppleElement]
                        for link in linkNodes {
                            item.itemLink = link.object(forKey: "href")
                        }
                        
                        let imageURLNodes = element.search(withXPathQuery: "//span[@class='b-poster-tile__image']/img") as! [TFHppleElement]
                        for image in imageURLNodes {
                            let posterLink = image.object(forKey: "src")
                            item.itemPoster = posterLink
                        }
                        
                        let titleNodes = element.search(withXPathQuery: "//span[@class='b-poster-tile__title-short']") as! [TFHppleElement]
                        for title in titleNodes {
                            item.itemTitle = title.text().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
            self.httpGET(httpSiteUrl + "/video/serials/?sort=new", referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error!)
                    return
                } else {
                    let doc = TFHpple(htmlData: data)
                    var newTVShowsArray = [Item]()
                    
                    let newTVShows = doc?.search(withXPathQuery: "//div[@class='b-poster-tile   ']") as! [TFHppleElement]
                    
                    for element in newTVShows {
                        let item = Item()
                        let linkNodes = element.search(withXPathQuery: "//a[@class='b-poster-tile__link']") as! [TFHppleElement]
                        for link in linkNodes {
                            item.itemLink = link.object(forKey: "href")
                        }
                        
                        let imageURLNodes = element.search(withXPathQuery: "//span[@class='b-poster-tile__image']/img") as! [TFHppleElement]
                        for image in imageURLNodes {
                            let posterLink = image.object(forKey: "src")
                            item.itemPoster = posterLink
                        }
                        
                        let titleNodes = element.search(withXPathQuery: "//span[@class='b-poster-tile__title-short']") as! [TFHppleElement]
                        for title in titleNodes {
                            item.itemTitle = title.text().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
    
    func getFavorites() {
        DispatchQueue.global().async { () -> Void in
            self.httpGET(httpSiteUrl + "/myfavourites.aspx?page=inprocess", referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error!)
                    return
                } else {
                    if let doc = TFHpple(htmlData: data) {
                        DispatchQueue.main.sync(execute: { () -> Void in
                            var favoritesArray = [Item]()
                            
                            var XPathQuery = "//div[@class='b-category m-theme-video ']"
                            guard let categoryElements = doc.search(withXPathQuery: XPathQuery) as? [TFHppleElement] else { return }
                            for categoryElement in categoryElements {
                                let item = Item()
                                
                                XPathQuery = "//span[@class='section-title']/b"
                                item.categoryName = (categoryElement.search(withXPathQuery: XPathQuery).last as? TFHppleElement)?.text()
                                
                                XPathQuery = "//b[@class='subject-link']/span"
                                item.itemTitle = (categoryElement.search(withXPathQuery: XPathQuery).last as? TFHppleElement)?.text()
                                
                                XPathQuery = "//a[@class='b-poster-thin m-video ']/@href"
                                item.itemLink = (categoryElement.search(withXPathQuery: XPathQuery).last as? TFHppleElement)?.text()
                                
                                XPathQuery = "//a[@class='b-poster-thin m-video ']/@style"
                                let wrappedString = (categoryElement.search(withXPathQuery: XPathQuery).last as? TFHppleElement)?.text()
                                
                                item.itemPoster = (matchesForRegexInText("(?<=\')(.*)(?=\')", text: wrappedString!)).first
                                
                                favoritesArray.append(item)
                            }
                        })
                    }
                }
            }
        }
    }
    
    func getItemDetails(_ item: Item) {
        DispatchQueue.global().async { () -> Void in
            self.httpGET(httpSiteUrl + item.itemLink!, referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error!)
                    return
                } else {
                    if let doc = TFHpple(htmlData: data) {
                        item.name = (doc.peekAtSearch(withXPathQuery: "//div[@class='b-tab-item__title-inner']/span")).text()!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        
                        if let altName = doc.peekAtSearch(withXPathQuery: "//div[@itemprop='alternativeHeadline']") {
                            item.altName = altName.text().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        }
                        
                        let itemInfo = doc.peekAtSearch(withXPathQuery: "//div[@class='item-info']")
                        
                        if let yearsNodes = itemInfo?.search(withXPathQuery: "//tr[2]/td[2]/a/span") {
                            var years = [String]()
                            for yearNode in yearsNodes {
                                years.append((yearNode as AnyObject).text())
                            }
                            
                            if yearsNodes.count == 1 {
                                if itemInfo?.search(withXPathQuery: "//span[@class='tag show-continues']/span").first != nil {
                                    years.append("...")
                                }
                            }
                            
                            item.year = years.joined(separator: "-")
                        }
                        
                        if let genreNodes = itemInfo?.search(withXPathQuery: "//span[@itemprop='genre']/a/span") {
                            var genres = [String]()
                            for node in genreNodes {
                                genres.append((node as AnyObject).text())
                            }
                            item.genre = (genres.joined(separator: ", ")).capitalized
                        }
                        
                        if item.itemLink!.contains("serials") {
                            let countryNodes = itemInfo?.search(withXPathQuery: "//tr[4]/td[2]/a/span") as! [TFHppleElement]
                            var countries = [String]()
                            for country in countryNodes {
                                countries.append(country.text())
                            }
                            item.country = countries.joined(separator: ", ")
                        } else {
                            let countryNodes = itemInfo?.search(withXPathQuery: "//tr[3]/td[2]/a/span") as! [TFHppleElement]
                            var countries = [String]()
                            for country in countryNodes {
                                countries.append(country.text())
                            }
                            item.country = countries.joined(separator: ", ")
                        }
                        
                        if let directorNodes = itemInfo?.search(withXPathQuery: "//span[@itemprop='director']/a/span") as? [TFHppleElement] {
                            var directors = [String]()
                            for director in directorNodes {
                                directors.append(director.text())
                            }
                            item.director = directors.joined(separator: ", ")
                        }
                        
                        if let actorNodes = itemInfo?.search(withXPathQuery: "//span[@itemprop='actor']/a/span") as? [TFHppleElement] {
                            var actors = [String]()
                            for actor in actorNodes {
                                actors.append(actor.text())
                            }
                            item.actors = actors.joined(separator: ", ")
                        }
                        
                        if let rating = itemInfo?.search(withXPathQuery: "//meta[@itemprop='ratingValue']/@content").first {
                            item.ratingValue = Float((rating as AnyObject).text())!/10
                        }
                        
                        if let upVoteValue = itemInfo?.search(withXPathQuery: "//div[contains(@class, 'vote-value_type_yes')]").first {
                            item.upVoteValue = (upVoteValue as AnyObject).text()
                        }
                        
                        if let downVoteValue = itemInfo?.search(withXPathQuery: "//div[contains(@class, 'vote-value_type_no')]").first {
                            item.downVoteValue = (downVoteValue as AnyObject).text()
                        }
                        
                        let thumbs = doc.search(withXPathQuery: "//a[@class='images-show']/@style")
                        if !(thumbs?.isEmpty)! {
                            item.thumbsUrl = []
                            for thumb in thumbs as! [TFHppleElement] {
                                var thumbLink = thumb.text()
                                //let thumbLink = matchesForRegexInText("(?<=\\()(.*)(?=\\))", text: attribute!).first
                                thumbLink = thumbLink?.components(separatedBy: "(").last
                                thumbLink = thumbLink?.components(separatedBy: ")").first
                                let biggerThumbLink = getBiggerThumbLink(thumbLink!, sizeIndex: "2")
                                item.thumbsUrl!.append(biggerThumbLink)
                            }
                        } else {
                            item.thumbsUrl = []
                            let biggerThumbLink = getBiggerThumbLink(item.itemPoster!, sizeIndex: "1")
                            item.thumbsUrl!.append(biggerThumbLink)
                        }
                        
                        if let similarMovies = doc.search(withXPathQuery: "//div[@class='b-poster-new ']") as? [TFHppleElement] {
                            item.similarItems = []
                            for movie in similarMovies {
                                let similarItem = Item()
                                similarItem.itemLink = ((movie.search(withXPathQuery: "//a/@href").first) as AnyObject).text()
                                
                                similarItem.itemTitle = ((movie.search(withXPathQuery: "//span[@class='m-poster-new__full_title']").first) as AnyObject).text()
                                
                                var posterLink = ((movie.search(withXPathQuery: "//span[contains(@class, 'image-poster')]/@style").first) as AnyObject).text()
                                posterLink = posterLink?.components(separatedBy: "('").last!
                                posterLink = posterLink?.components(separatedBy: "')").first!
                                similarItem.itemPoster = getBiggerThumbLink(posterLink!, sizeIndex: "6")
                                
                                item.similarItems!.append(similarItem)
                            }
                        }
                        
                        if let itemDescription = doc.peekAtSearch(withXPathQuery: "//div[@class='b-tab-item__description']/span/p") {
                            item.itemDescription = itemDescription.text().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        } else if let itemDescription = doc.peekAtSearch(withXPathQuery: "//div[@class='b-tab-item__description']/p") {
                            item.itemDescription = itemDescription.text().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        }
                        
                        item.hasDetails = true
                    }
                }
            }
        }
    }
    
    func readDirectory(_ item: Item) {
        let folderUrl = getFullUrl(item.itemLink!)
        var isFilelist = false
        
        while isFilelist == false {
            let getUrl = "\(folderUrl)?ajax&folder=\(item.folderId)"
            
            httpGET(getUrl, referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error!)
                    return
                } else {
                    let doc = TFHpple(htmlData: data)
                    
                    if item.folderId == "0" {
                        let hasBlockedContent = doc?.peekAtSearch(withXPathQuery: "//div[@id='file-block-text']")
                        if hasBlockedContent != nil {
                            // Show message "Blocked Content"
                        }
                    }
                    
                    if let filelist = doc?.search(withXPathQuery: "ul[@class='filelist m-current']").last as? TFHppleElement {
                        isFilelist = true
                        
                        if let files = filelist.search(withXPathQuery: "//li[contains(@class, 'video-hdrip')]") as? [TFHppleElement] {
                            for file in files {
                                // get links & sizes
                            }
                            
                        }
                        
                    } else if let folderList = doc?.search(withXPathQuery: "//*[starts-with(@class,'filelist')]").last as? TFHppleElement {
                        isFilelist = false
                        // get folderId
                        for folder in folderList.children {
                            // Get folder 
                            
                            
                            var identifier: String!
                            identifier = ((folder as AnyObject).search(withXPathQuery: "//div[2]/a[1]").last as! TFHppleElement).attributes["name"] as! String
                            identifier = identifier.replacingOccurrences(of: "fl", with: "")
                            item.folderId = identifier;
                        }
                    }
                    
                    
//                    for folder in folderList.children {
//                        guard let classValue = folder.attributes["class"] as? String else { continue }
//                        if classValue.hasPrefix("folder") {
//                            
//                            // only root folders contains 'header' tag
//                            let isRootFolder = folder.childrenWithClassName("header").count > 0
//                            
//                            // identifier
//                            var identifier: String!
//                            identifier = (folder.searchWithXPathQuery("//div[2]/a[1]").last as! TFHppleElement).attributes["name"] as! String
//                            identifier = identifier.stringByReplacingOccurrencesOfString("fl", withString: "")
//                            item.folderId = identifier;
//
//                            
//                            // quality
//                            if (isRootFolder) {
//                                folder.videoQuality = VideoQuality.Undefined
//                            } else {
//                                let qualityString = (folder.searchWithXPathQuery("//div[1]").last as! TFHppleElement).attributes["class"] as! String
//                                if ((qualityString as NSString).rangeOfString("m-hd").location != NSNotFound) {
//                                    folder.videoQuality = VideoQuality.HD
//                                } else if ((qualityString as NSString).rangeOfString("m-sd").location != NSNotFound) {
//                                    folder.videoQuality = VideoQuality.SD
//                                } else {
//                                    folder.videoQuality = VideoQuality.Undefined
//                                }
//                            }
//                            
//                            // language
//                            if (isRootFolder) {
//                                folder.language = VideoLanguage.Undefined
//                            } else {
//                                let languageString = (folder.searchWithXPathQuery("//div[2]/a[1]").last as! TFHppleElement).attributes["class"] as! String
//                                if ((languageString as NSString).rangeOfString("m-en").location != NSNotFound) {
//                                    folder.language = VideoLanguage.EN
//                                } else if ((languageString as NSString).rangeOfString("m-ru").location != NSNotFound) {
//                                    folder.language = VideoLanguage.RU
//                                } else if ((languageString as NSString).rangeOfString("m-ua").location != NSNotFound) {
//                                    folder.language = VideoLanguage.UA
//                                } else {
//                                    folder.language = VideoLanguage.Undefined
//                                }
//                            }
//                            
//                            folder.details = (folder.childrenWithClassName("material-details").first as! TFHppleElement).text()
//                            folder.size = (folder.childrenWithClassName("material-details").last as! TFHppleElement).text()
//                            folder.dateString = (folder.childrenWithClassName("material-date").last as! TFHppleElement).text()
//                            
//                            items.append(folder)
//                        } else if (classValue as NSString).rangeOfString("file").location != NSNotFound {
//                            let file = File()
//                            
//                            file.name = (folder.searchWithXPathQuery("//span/span").last as! TFHppleElement).text()
//                            file.size = (folder.searchWithXPathQuery("//a/span").last as! TFHppleElement).text()
//                            
//                            let typeString = folder.attributes["class"] as! String
//                            if ((typeString as NSString).rangeOfString("m-file-new_type_video").location != NSNotFound) {
//                                file.type = FileType.Video
//                            } else if ((typeString as NSString).rangeOfString("m-file-new_type_audio").location != NSNotFound) {
//                                file.type = FileType.Audio
//                            } else {
//                                file.type = FileType.Undefined
//                            }
//                            
//                            let pathComponent = (folder.searchWithXPathQuery("//a").last as! TFHppleElement)["href"] as! String
//                            let fileURL = NSURL(scheme: "http", host: "brb.to", path: pathComponent)
//                            file.URL = fileURL
//                            
//                            items.append(file)
//                        }
//                    }
                }
            }
        }
    }
}
