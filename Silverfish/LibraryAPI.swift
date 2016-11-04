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
    
    private let persistencyManager: PersistencyManager
    private let httpClient: HTTPClient
    //private var mainPageItems = [String : [Item]]()

    private let isOnline: Bool

    override init() {
        persistencyManager = PersistencyManager()
        httpClient = HTTPClient()
        isOnline = false
        
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.downloadImage(_:)), name: "DownloadImageNotification", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func getItems() -> [Item] {
        return persistencyManager.getItems()
    }
    
    func addItem(item: Item, index: Int) {
        persistencyManager.addItem(item, index: index)
    }
    
    func deleteItem(index: Int) {
        persistencyManager.deleteItemAtIndex(index)
    }
    
    func getMainPageItems() -> [[Item]] {
        return persistencyManager.getMainPageItems()
    }
    
    func addRowToMainPage(itemsArray: [Item], atIndex: Int) {
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
    
    func httpGET(url: String, referer: String!, postParams: Dictionary<String, AnyObject>?, callback: (NSData?, String?) -> Void) {
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
    
    func downloadImage(notification: NSNotification) {
        
        let userInfo = notification.userInfo as! [String: AnyObject]
        let imageView = userInfo["imageView"] as! UIImageView?
        let coverUrl = userInfo["coverUrl"] as! String
        
        if let imageViewUnWrapped = imageView {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                self.httpClient.getImage(coverUrl, callback: { (data, error) in
                    let downloadedImage = UIImage(data: data!)
                    
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        imageViewUnWrapped.image = downloadedImage
                    })
                })
            })
        }
    }
    
    func downloadImage(at URL: String, success: ((UIImage) -> ())? ) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            self.httpClient.getImage(URL, callback: { (data, error) in
                let downloadedImage = UIImage(data: data!)
                defer {
                    if success != nil {
                        dispatch_sync(dispatch_get_main_queue(), { () -> Void in
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
    
    func retrieveSearchResults(searchText: String, success: (([Item]) -> ())? ) {
        let encodedSearchQuery = searchText.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        let parameters = "search.aspx?search=\(encodedSearchQuery)"
        let searchUrl = httpSiteUrl + "/" + parameters
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.httpGET(searchUrl, referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(">>> Error getting data: \(error)")
                } else {
                    var searchResuts = [Item]()
                    defer {
                        if success != nil {
                            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                                success!(searchResuts)
                            })
                        }
                    }
                    
                    let doc = TFHpple(HTMLData: data)
                    let results = doc.searchWithXPathQuery("//a[@class='b-search-page__results-item  m-video']") as! [TFHppleElement]
                    
                    for element in results {
                        let item = Item()
                        item.itemLink = element.objectForKey("href")
                        
                        // TODO: Check item link for 404
                        // If so, do not add item to list.
                        
                        let posterUrl = (element.searchWithXPathQuery("//img/@src").last as? TFHppleElement)?.text()
                        item.itemPoster = getBiggerThumbLink(posterUrl!, sizeIndex: "6")
                        
                        item.itemTitle = (element.searchWithXPathQuery("//@title").last as? TFHppleElement)?.text()
                        
                        item.genre = (element.searchWithXPathQuery("//span[@class='b-search-page__results-item-genres']").first as? TFHppleElement)?.text().capitalizedString
                        item.upVoteValue = (element.searchWithXPathQuery("//span[@class='b-search-page__results-item-rating-positive']").first as? TFHppleElement)?.text()
                        item.downVoteValue = (element.searchWithXPathQuery("//span[@class='b-search-page__results-item-rating-negative']").first as? TFHppleElement)?.text()
                        
                        //item.itemDescription = (element.searchWithXPathQuery("//span[@class='b-search-page__results-item-description']").last as? TFHppleElement)?.text().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        
                        searchResuts.append(item)
                    }
                }
            }
        }
    }
    
    func getMainItemsRow(at URL: String, success: (([Item]) -> ())? ) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.httpGET(httpSiteUrl + URL, referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error)
                    return
                } else {
                    var resultsArray = [Item]()
                    defer {
                        if success != nil {
                            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                                success!(resultsArray)
                            })
                        }
                    }
                    
                    let doc = TFHpple(HTMLData: data)
                    let results = doc.searchWithXPathQuery("//div[@class='b-poster-tile   ']") as! [TFHppleElement]
                    
                    for element in results {
                        let item = Item()
                        let linkNodes = element.searchWithXPathQuery("//a[@class='b-poster-tile__link']") as! [TFHppleElement]
                        for link in linkNodes {
                            item.itemLink = link.objectForKey("href")
                        }
                        
                        let imageURLNodes = element.searchWithXPathQuery("//span[@class='b-poster-tile__image']/img") as! [TFHppleElement]
                        for image in imageURLNodes {
                            let posterLink = image.objectForKey("src")
                            item.itemPoster = posterLink
                        }
                        
                        let titleNodes = element.searchWithXPathQuery("//span[@class='b-poster-tile__title-short']") as! [TFHppleElement]
                        for title in titleNodes {
                            item.itemTitle = title.text().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        }
                        
                        //self.getItemDetails(item)
                        
                        resultsArray.append(item)
                    }
                }
            }
        }
    }
    
    func getPopularItems() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.httpGET(httpSiteUrl + "/video/films/?sort=trend", referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error)
                    return
                } else {
                    let doc = TFHpple(HTMLData: data)
                    var popularMoviesArray = [Item]()
                    
                    let popularMovies = doc.searchWithXPathQuery("//div[@class='b-poster-tile   ']") as! [TFHppleElement]
                    
                    for element in popularMovies {
                        let item = Item()
                        let linkNodes = element.searchWithXPathQuery("//a[@class='b-poster-tile__link']") as! [TFHppleElement]
                        for link in linkNodes {
                            item.itemLink = link.objectForKey("href")
                        }
                        
                        let imageURLNodes = element.searchWithXPathQuery("//span[@class='b-poster-tile__image']/img") as! [TFHppleElement]
                        for image in imageURLNodes {
                            let posterLink = image.objectForKey("src")
                            item.itemPoster = posterLink
                        }
                        
                        let titleNodes = element.searchWithXPathQuery("//span[@class='b-poster-tile__title-short']") as! [TFHppleElement]
                        for title in titleNodes {
                            item.itemTitle = title.text().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        }
                        
                        popularMoviesArray.append(item)
                    }

                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        self.addRowToMainPage(popularMoviesArray, atIndex: 0)
                        NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
                    })
                }
            }
        }
    }
    
    func getNewMovies() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.httpGET(httpSiteUrl + "/video/films/?sort=new", referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error)
                    return
                } else {
                    let doc = TFHpple(HTMLData: data)
                    var newMoviesArray = [Item]()
                    
                    let newMovies = doc.searchWithXPathQuery("//div[@class='b-poster-tile   ']") as! [TFHppleElement]
                    
                    for element in newMovies {
                        let item = Item()
                        let linkNodes = element.searchWithXPathQuery("//a[@class='b-poster-tile__link']") as! [TFHppleElement]
                        for link in linkNodes {
                            item.itemLink = link.objectForKey("href")
                        }
                        
                        let imageURLNodes = element.searchWithXPathQuery("//span[@class='b-poster-tile__image']/img") as! [TFHppleElement]
                        for image in imageURLNodes {
                            let posterLink = image.objectForKey("src")
                            item.itemPoster = posterLink
                        }
                        
                        let titleNodes = element.searchWithXPathQuery("//span[@class='b-poster-tile__title-short']") as! [TFHppleElement]
                        for title in titleNodes {
                            item.itemTitle = title.text().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        }
                        
                        newMoviesArray.append(item)
                    }

                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        self.addRowToMainPage(newMoviesArray, atIndex: 1)
                        NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
                    })
                }
            }
        }
    }
    
    func getNewTVShows() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.httpGET(httpSiteUrl + "/video/serials/?sort=new", referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error)
                    return
                } else {
                    let doc = TFHpple(HTMLData: data)
                    var newTVShowsArray = [Item]()
                    
                    let newTVShows = doc.searchWithXPathQuery("//div[@class='b-poster-tile   ']") as! [TFHppleElement]
                    
                    for element in newTVShows {
                        let item = Item()
                        let linkNodes = element.searchWithXPathQuery("//a[@class='b-poster-tile__link']") as! [TFHppleElement]
                        for link in linkNodes {
                            item.itemLink = link.objectForKey("href")
                        }
                        
                        let imageURLNodes = element.searchWithXPathQuery("//span[@class='b-poster-tile__image']/img") as! [TFHppleElement]
                        for image in imageURLNodes {
                            let posterLink = image.objectForKey("src")
                            item.itemPoster = posterLink
                        }
                        
                        let titleNodes = element.searchWithXPathQuery("//span[@class='b-poster-tile__title-short']") as! [TFHppleElement]
                        for title in titleNodes {
                            item.itemTitle = title.text().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        }
                        
                        newTVShowsArray.append(item)
                    }

                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        self.addRowToMainPage(newTVShowsArray, atIndex: 2)
                        NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
                    })
                }
            }
        }
    }
    
    func getFavorites() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.httpGET(httpSiteUrl + "/myfavourites.aspx?page=inprocess", referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error)
                    return
                } else {
                    if let doc = TFHpple(HTMLData: data) {
                        dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                            var favoritesArray = [Item]()
                            
                            var XPathQuery = "//div[@class='b-category m-theme-video ']"
                            guard let categoryElements = doc.searchWithXPathQuery(XPathQuery) as? [TFHppleElement] else { return }
                            for categoryElement in categoryElements {
                                let item = Item()
                                
                                XPathQuery = "//span[@class='section-title']/b"
                                item.categoryName = (categoryElement.searchWithXPathQuery(XPathQuery).last as? TFHppleElement)?.text()
                                
                                XPathQuery = "//b[@class='subject-link']/span"
                                item.itemTitle = (categoryElement.searchWithXPathQuery(XPathQuery).last as? TFHppleElement)?.text()
                                
                                XPathQuery = "//a[@class='b-poster-thin m-video ']/@href"
                                item.itemLink = (categoryElement.searchWithXPathQuery(XPathQuery).last as? TFHppleElement)?.text()
                                
                                XPathQuery = "//a[@class='b-poster-thin m-video ']/@style"
                                let wrappedString = (categoryElement.searchWithXPathQuery(XPathQuery).last as? TFHppleElement)?.text()
                                
                                item.itemPoster = (matchesForRegexInText("(?<=\')(.*)(?=\')", text: wrappedString!)).first
                                
                                favoritesArray.append(item)
                            }
                        })
                    }
                }
            }
        }
    }
    
    func getItemDetails(item: Item) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.httpGET(httpSiteUrl + item.itemLink!, referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error)
                    return
                } else {
                    if let doc = TFHpple(HTMLData: data) {
                        item.name = (doc.peekAtSearchWithXPathQuery("//div[@class='b-tab-item__title-inner']/span")).text()!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        
                        if let altName = doc.peekAtSearchWithXPathQuery("//div[@itemprop='alternativeHeadline']") {
                            item.altName = altName.text().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        }
                        
                        let itemInfo = doc.peekAtSearchWithXPathQuery("//div[@class='item-info']")
                        
                        if let yearsNodes = itemInfo.searchWithXPathQuery("//tr[2]/td[2]/a/span") {
                            var years = [String]()
                            for yearNode in yearsNodes {
                                years.append(yearNode.text())
                            }
                            
                            if yearsNodes.count == 1 {
                                if itemInfo.searchWithXPathQuery("//span[@class='tag show-continues']/span").first != nil {
                                    years.append("...")
                                }
                            }
                            
                            item.year = years.joinWithSeparator("-")
                        }
                        
                        if let genreNodes = itemInfo.searchWithXPathQuery("//span[@itemprop='genre']/a/span") {
                            var genres = [String]()
                            for node in genreNodes {
                                genres.append(node.text())
                            }
                            item.genre = (genres.joinWithSeparator(", ")).capitalizedString
                        }
                        
                        if let rating = itemInfo.searchWithXPathQuery("//meta[@itemprop='ratingValue']/@content").first {
                            item.ratingValue = Float(rating.text())!/10
                        }
                        
                        if let upVoteValue = itemInfo.searchWithXPathQuery("//div[contains(@class, 'vote-value_type_yes')]").first {
                            item.upVoteValue = upVoteValue.text()
                        }
                        
                        if let downVoteValue = itemInfo.searchWithXPathQuery("//div[contains(@class, 'vote-value_type_no')]").first {
                            item.downVoteValue = downVoteValue.text()
                        }
                        
                        let thumbs = doc.searchWithXPathQuery("//a[@class='images-show']/@style")
                        if !thumbs.isEmpty {
                            item.thumbsUrl = []
                            for thumb in thumbs as! [TFHppleElement] {
                                var thumbLink = thumb.text()
                                //let thumbLink = matchesForRegexInText("(?<=\\()(.*)(?=\\))", text: attribute!).first
                                thumbLink = thumbLink?.componentsSeparatedByString("(").last
                                thumbLink = thumbLink?.componentsSeparatedByString(")").first
                                let biggerThumbLink = getBiggerThumbLink(thumbLink!, sizeIndex: "2")
                                item.thumbsUrl!.append(biggerThumbLink)
                            }
                        } else {
                            item.thumbsUrl = []
                            let biggerThumbLink = getBiggerThumbLink(item.itemPoster!, sizeIndex: "1")
                            item.thumbsUrl!.append(biggerThumbLink)
                        }
                        
                        if let similarMovies = doc.searchWithXPathQuery("//div[@class='b-poster-new ']") as? [TFHppleElement] {
                            item.similarItems = []
                            for movie in similarMovies {
                                let similarItem = Item()
                                similarItem.itemLink = (movie.searchWithXPathQuery("//a/@href").first)?.text()
                                
                                similarItem.itemTitle = (movie.searchWithXPathQuery("//span[@class='m-poster-new__full_title']").first)?.text()
                                
                                var posterLink = (movie.searchWithXPathQuery("//span[contains(@class, 'image-poster')]/@style").first)?.text()
                                posterLink = posterLink?.componentsSeparatedByString("('").last!
                                posterLink = posterLink?.componentsSeparatedByString("')").first!
                                similarItem.itemPoster = getBiggerThumbLink(posterLink!, sizeIndex: "6")
                                
                                item.similarItems!.append(similarItem)
                            }
                        }
                        
                        if let itemDescription = doc.peekAtSearchWithXPathQuery("//div[@class='b-tab-item__description']/span/p") {
                            item.itemDescription = itemDescription.text().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        } else if let itemDescription = doc.peekAtSearchWithXPathQuery("//div[@class='b-tab-item__description']/p") {
                            item.itemDescription = itemDescription.text().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        }
                        
                        item.hasDetails = true
                    }
                }
            }
        }
    }
    
    func readDirectory(item: Item) {
        let folderUrl = getFullUrl(item.itemLink!)
        var isFilelist = false
        
        while isFilelist == false {
            let getUrl = "\(folderUrl)?ajax&folder=\(item.folderId)"
            
            httpGET(getUrl, referer: httpSiteUrl, postParams: nil) { (data, error) in
                if error != nil {
                    print(error)
                    return
                } else {
                    let doc = TFHpple(HTMLData: data)
                    
                    if item.folderId == "0" {
                        let hasBlockedContent = doc.peekAtSearchWithXPathQuery("//div[@id='file-block-text']")
                        if hasBlockedContent != nil {
                            // Show message "Blocked Content"
                        }
                    }
                    
                    if let filelist = doc.searchWithXPathQuery("ul[@class='filelist m-current']").last as? TFHppleElement {
                        isFilelist = true
                        
                        if let files = filelist.searchWithXPathQuery("//li[contains(@class, 'video-hdrip')]") as? [TFHppleElement] {
                            for file in files {
                                // get links & sizes
                            }
                            
                        }
                        
                    } else if let folderList = doc.searchWithXPathQuery("//*[starts-with(@class,'filelist')]").last as? TFHppleElement {
                        isFilelist = false
                        // get folderId
                        
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
