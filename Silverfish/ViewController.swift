//
//  ViewController.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 4/13/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
  
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    
    var mainPageItems: [[Item]]?
    var searchResults = [Item]()
    //var mainPageItemsCollection: [MainPageItemsRow]?
    
    lazy private var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.barStyle = .Black
        searchController.searchBar.searchBarStyle = .Prominent
        searchController.searchBar.barTintColor = UIColor(red: 48/255, green: 58/255, blue: 74/255, alpha: 1.0)
        
        return searchController
    }()
    
    private var searchTimer: NSTimer!
    
    let defaults = NSUserDefaults.standardUserDefaults()
    let libAPI = LibraryAPI.sharedInstance
    var login = ""
    var password = ""
    var userName = ""
    
    var isLogged = false
    //var categories = [String]()
    var categories = ["Popular", "Recently Added Movies", "Recently Added TV Shows"]
    
    func setUserName () {
        defaults.synchronize()
        
        if defaults.stringForKey("userName") != nil || defaults.stringForKey("userName") != "" {
            //let name = defaults.stringForKey("userName")
            //print("User Name is: \(name)")
            self.userName = defaults.stringForKey("userName")!
        } else {
            print("User Name is not set")
        }
    }
    
    func logIn() {
        if login.isEmpty || password.isEmpty {
            print("Login/Password is not set.")
            return
        } else {
            libAPI.httpGET(httpSiteUrl + "/login.aspx", referer: httpSiteUrl, postParams: ["login": login, "passwd": password, "remember": "on"]){
                (data, error) -> Void in
                if error != nil {
                    self.title = "No Connection!"
                    print(error)
                    return
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.checkLogin()
                    })
                    
                }
            }
        }
        
    }
    
    func logOut() {
        libAPI.httpGET(httpSiteUrl + "/logout.aspx", referer: httpSiteUrl, postParams: nil) {
            (data, error) -> Void in
            if error != nil {
                print(error)
            } else {
                //let queue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                dispatch_async(dispatch_get_main_queue(), {
                    self.checkLogin()
                    print("Removing user entries...")
                    self.defaults.removeObjectForKey("userName")
                    self.defaults.synchronize()
                })
            }
        }
    }
    
    func checkLogin() -> Bool {
        let siteUrl = NSURL(string: httpSiteUrl)!
        guard let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(siteUrl) else { return false }
        
        for cookie in cookies {
            if cookie.name == "fs_us" {
                if self.defaults.stringForKey("userName") == nil || self.defaults.stringForKey("userName") == "" {
                    let userCreds = cookie.value
                    let userCredsDecoded = NSData(data: ((userCreds.stringByRemovingPercentEncoding)?.dataUsingEncoding(NSUTF8StringEncoding))!)
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(userCredsDecoded, options: .MutableContainers)
                        
                        let userName = json["l"] as! NSString

                        defaults.setObject(userName, forKey: "userName")
                        defaults.synchronize()
                        
                    } catch {
                        print("error serializing JSON: \(error)")
                    }
                }
                self.setUserName()
                self.isLogged = true
                print("Logged In")
                self.loginButton.setTitle(self.userName, forState: .Normal)
                return true
            }
        }
        self.isLogged = false
        print("Logged Out")
        self.loginButton.setTitle("Log In", forState: .Normal)
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.reloadMainPageItems(_:)), name:"reload", object: nil)
        LoadingView.shared.showOverlay(super.view)
        checkLogin()
        
        self.title = "Main Page"
        addLogo()
        tableView.tableFooterView = footerView
        loginButton.layer.borderWidth = 1
        loginButton.layer.borderColor = UIColor( red: 111/255, green: 113/255, blue:121/255, alpha: 1.0 ).CGColor

        let topView = UIView(frame: CGRectMake(0, -480, 600, 480))
        //topView.backgroundColor = UIColor(red: 48/255, green: 58/255, blue: 74/255, alpha: 1.0)
        topView.backgroundColor = UIColor(red: 31/255, green: 36/255, blue: 44/255, alpha: 1.0)
        tableView.addSubview(topView)
        
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        //tableView.tableHeaderView?.backgroundColor = UIColor(red: 48/255, green: 58/255, blue: 74/255, alpha: 1.0)
        
        libAPI.loadData()
        //getMainPageItems()
        tableView.contentOffset = CGPointMake(0, searchController.searchBar.frame.size.height)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
//    func getMainPageItems() {
//        let rows: Array<Dictionary<String, String>> = [["title": "Popular",                "url": "/video/films/?sort=trend"],
//                    ["title": "Recently Added Movies",  "url": "/video/films/?sort=new"],
//                    ["title": "Recently Added TV Shows","url": "/video/serials/?sort=new"]]
//        
//        mainPageItemsCollection = [MainPageItemsRow]()
//        mainPageItemsCollection?.reserveCapacity(rows.count)
//        
//        for row in rows {
//            libAPI.getMainItemsRow(at: row["url"]!, success: { (array) in
//                let itemRow = MainPageItemsRow()
//                itemRow.row = array
//                itemRow.title = row["title"]
//                self.mainPageItemsCollection?.append(itemRow)
//                self.reloadTable()
//            })
//        }
//    }
    
    private func configureSearchBar() {
        
        let searchBar = self.searchController.searchBar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        let searchBarContainer = UIView(frame: CGRect(x: 0, y: 0, width: 600, height: 19))
        searchBarContainer.addSubview(searchBar)
        
        let views = ["searchBar" : searchBar]
        searchBarContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[searchBar]-0-|",
            options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        searchBarContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[searchBar]-0-|",
            options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        
        //navigationItem.titleView = searchBarContainer
        tableView.tableHeaderView = searchBarContainer
        //footerView.hidden = true
    }
    
    func performSearch() {
        guard let pattern = searchController.searchBar.text else { return }
        if pattern.characters.count > 0 {
            LoadingView.shared.showOverlay(super.view)
            libAPI.retrieveSearchResults(pattern, success: { (searchResults) -> () in
                self.searchResults = searchResults
                self.reloadTable()
            })
        }
    }
    
    func addLogo() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 91, height: 19))
        imageView.contentMode = .ScaleAspectFit
        let image = UIImage(named: "logo")
        imageView.image = image
        navigationItem.titleView = imageView
    }
    
    func reloadMainPageItems(notification: NSNotification) {
        self.mainPageItems = libAPI.getMainPageItems()
        reloadTable()
        //LoadingView.shared.hideOverlayView()
    }
    
    func reloadTable() {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
            LoadingView.shared.hideOverlayView()
        })
    }
    
    //MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "detailViewSegue" {
            
            if let cell = sender as? ItemCell {
                let destination = segue.destinationViewController as! DetailViewController
                destination.item = cell.item
            } else if let cell = sender as? SearchResultCell {
                let destination = segue.destinationViewController as! DetailViewController
                destination.item = cell.item
                if searchController.active {
                    searchController.searchBar.resignFirstResponder()
                }
            }
        }
    }
    
    // MARK: Login Button actions
    @IBAction func loginButtonPressed(sender: UIButton) {
        if self.isLogged {
            showLogoutDialog(self.userName)
        } else {
            showLoginDialog("Log in to your account.")
        }
    }
    
    func showLoginDialog(message: String) {
        let myAlert = UIAlertController(title: "Log In", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        var loginString = ""
        var passwordString = ""
        
        myAlert.addTextFieldWithConfigurationHandler { (loginTextField) in
            
            if self.defaults.stringForKey("login") != nil {
                loginTextField.text = self.defaults.stringForKey("login")!
            } else {
                loginTextField.placeholder = "Login"
                loginString = loginTextField.text!
            }
        }
        
        myAlert.addTextFieldWithConfigurationHandler { (passTextField) in
            
            passTextField.secureTextEntry = true
            
            if self.defaults.stringForKey("password") != nil {
                passTextField.text = self.defaults.stringForKey("password")!
            } else {
                passTextField.placeholder = "Password"
                passwordString = passTextField.text!
            }
        }
        
        let loginAction = UIAlertAction(title: "Log In", style: UIAlertActionStyle.Default) { (action) in
            
            let loginTextField = myAlert.textFields![0] as UITextField
            let passTextField = myAlert.textFields![1] as UITextField
            
            loginString = loginTextField.text!
            passwordString = passTextField.text!
            
            if self.login.isEmpty && self.password.isEmpty {
                
                if (loginString.isEmpty) || (passwordString.isEmpty) {
                    //TODO: displayAlert("All fields are required")
                    return
                }
                
                self.defaults.setObject(loginString, forKey: "login")
                self.defaults.setObject(passwordString, forKey: "password")
                self.defaults.synchronize()
                
                self.login = loginString
                self.password = passwordString
                
            }
            self.logIn()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        myAlert.addAction(loginAction)
        myAlert.addAction(cancelAction)
        
        self.presentViewController(myAlert, animated: true, completion: nil)
    }
    
    func showLogoutDialog(message: String) {
        let myAlert = UIAlertController(title: "Logged as:", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let logoutAction = UIAlertAction(title: "Log Out", style: UIAlertActionStyle.Default) { (action) in
            self.logOut()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        myAlert.addAction(logoutAction)
        myAlert.addAction(cancelAction)
        
        self.presentViewController(myAlert, animated: true, completion: nil)
    }
    
    // MARK: TableView Data Source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if searchController.active {
            if searchResults.isEmpty {
                return 0
            }
            return 1
        }
        guard let mainPageItemsRows = mainPageItems else {
            return 0
        }
        return mainPageItemsRows.count
    }
    
//    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        if searchController.active {
//            return nil
//        }
//        return mainPageItemsCollection?[section].title
//    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active {
            return searchResults.count
        }
        return 1
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if searchController.active {
            return nil
        }
        
        let headerCell = tableView.dequeueReusableCellWithIdentifier("customHeaderCell") as! CustomHeaderCell
        headerCell.headerLabel.text = categories[section]
        return headerCell
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if searchController.active && searchController.searchBar.text != "" {
            let cell = tableView.dequeueReusableCellWithIdentifier("searchResultCell", forIndexPath: indexPath) as! SearchResultCell
            let item = searchResults[indexPath.row]
            let view = ItemView(frame: cell.posterView.bounds, posterURL: item.itemPoster!)
            cell.posterView.addSubview(view)
            
            cell.titleLabel.text = item.itemTitle
            cell.genreLabel.text = item.genre
            cell.upVoteLabel.text = item.upVoteValue
            cell.downVoteLabel.text = item.downVoteValue
            
            if !item.hasDetails {
                libAPI.getItemDetails(item)
            }
            
            cell.item = item
            return cell
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        return cell
    }
    
    // MARK: TableView Delegate
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let tableViewCell = cell as? TableViewCell else { return }
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.section)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if searchController.active {
            return 144.0
        } else {
            return 175.0
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if searchController.active {
            return 0.0
        }
        return 28.0
    }
}


// MARK: Collection View
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let mainPageItemsRows = mainPageItems else {
            return 0
        }
        return mainPageItemsRows[collectionView.tag].count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("itemCell", forIndexPath: indexPath) as! ItemCell
        let item = mainPageItems![(collectionView.tag)][indexPath.row]
        //let item = mainPageItemsCollection![(collectionView.tag)].row![indexPath.row]

        let view = ItemView(frame: cell.bounds, posterURL: item.itemPoster!)
        cell.addSubview(view)
        
        if !item.hasDetails {
            libAPI.getItemDetails(item)
        }
        
        cell.item = item
        return cell
    }
}

extension ViewController: UISearchBarDelegate, UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchTimer?.invalidate()
        searchTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self,
                                                             selector: #selector(ViewController.performSearch), userInfo: nil, repeats: false)
        
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        footerView.hidden = true
        reloadTable()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchResults.removeAll()
        searchController.active = false
        footerView.hidden = false
        reloadTable()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if  searchText.characters.count == 0 {
            searchResults.removeAll()
            //reloadTable()
        }
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        performSearch()
        searchController.searchBar.resignFirstResponder()
    }
}
