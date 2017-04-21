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
    
    lazy fileprivate var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.barStyle = .black
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.barTintColor = UIColor(red: 48/255, green: 58/255, blue: 74/255, alpha: 1.0)
        
        return searchController
    }()
    
    fileprivate var searchTimer: Timer!
    
    let defaults = UserDefaults.standard
    let libAPI = LibraryAPI.sharedInstance
    var login = ""
    var password = ""
    var userName = ""
    
    var isLogged = false
    //var categories = [String]()
    var categories = ["Popular", "Recently Added Movies", "Recently Added TV Shows"]
    
    func setUserName () {
        defaults.synchronize()
        
        if defaults.string(forKey: "userName") != nil || defaults.string(forKey: "userName") != "" {
            self.userName = defaults.string(forKey: "userName")!
            print("User Name is: \(defaults.string(forKey: "userName")!)")
        } else {
            print("User Name is not set")
        }
    }
    
    func logIn() {
        if login.isEmpty || password.isEmpty {
            print("Login/Password is not set.")
            return
        } else {
            let siteUrl = httpSiteUrl
            libAPI.httpGET(siteUrl + "/login.aspx", referer: siteUrl, postParams: ["login": login, "passwd": password, "remember": "on"]){
                (data, response, error) -> Void in
                if error != nil {
                    self.title = "No Connection!"
                    print(error!)
                    return
                } else {
                    DispatchQueue.main.async(execute: {
                        self.checkLogin()
                    })
                    
                }
            }
        }
        
    }
    
    func logOut() {
        libAPI.httpGET(httpSiteUrl + "/logout.aspx", referer: httpSiteUrl, postParams: nil) {
            (data, response, error) -> Void in
            if error != nil {
                print(error!)
            } else {
                DispatchQueue.main.async(execute: {
                    self.checkLogin()
                    //print("Removing user entries...")
                    self.defaults.removeObject(forKey: "userName")
                    self.defaults.synchronize()
                })
            }
        }
    }
    
    func checkLogin() {
        let url = URL(string: httpSiteUrl)!
        guard let cookies = HTTPCookieStorage.shared.cookies(for: url) else { return }
        
        for cookie in cookies {
            //print(cookie)
            if cookie.name == "zzm_usess" {
//                do {
//                    let json = try JSONSerialization.jsonObject(with: NSData(base64Encoded: cookie.value, options: .init(rawValue: 0))! as Data, options: .allowFragments) as! NSDictionary
//                    for (key, value) in json {
//                        print("\(key): \(value)" )
//                    }
//                    
//                } catch let error {
//                    print(error.localizedDescription)
//                }
//                let string = cookie.value.characters.split(separator: ".").map(String.init)
//                for substring in string {
//                    let data = NSData(base64Encoded: substring, options: .ignoreUnknownCharacters)
//                    //let decodedString = String.init(data: data! as Data, encoding: .utf8)
//                    print(substring)
//                    print(data!)
//                }
//                let data = NSData(base64Encoded: cookie.value, options: .ignoreUnknownCharacters)
//                print(cookie.value)
//                print(data!)
                
//                let userCreds = cookie.value as NSString
//                let userCredsDecoded = NSData(data: ((userCreds.removingPercentEncoding)?.data(using: String.Encoding.utf8))!) as Data
//                do {
//                    let json = try JSONSerialization.jsonObject(with: userCredsDecoded, options: .mutableContainers) as? [String: Any]
//                    
//                    for (key, value) in json! {
//                        print("\(key): \(value)" )
//                    }
//                    //let userName = json?["l"] as! NSString
//                } catch {
//                    print(error.localizedDescription)
//                }
                
                self.isLogged = true
                break
            } else {
                self.isLogged = false
            }
        }
        
        if isLogged {
            self.login = self.defaults.string(forKey: "login")!
            print("Logged In")
            self.loginButton.setTitle(self.login, for: UIControlState())
        } else {
            print("Logged Out")
            self.loginButton.setTitle("Log In", for: UIControlState())
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reloadMainPageItems(_:)), name:NSNotification.Name(rawValue: "reload"), object: nil)
        LoadingView.shared.showOverlay((navigationController?.view)!)
        checkLogin()
        
        self.title = "Main Page"
        addLogo()
        tableView.tableFooterView = footerView
        loginButton.layer.borderWidth = 1
        loginButton.layer.borderColor = UIColor( red: 111/255, green: 113/255, blue:121/255, alpha: 1.0 ).cgColor

        let topView = UIView(frame: CGRect(x: 0, y: -480, width: 600, height: 480))
        topView.backgroundColor = UIColor(red: 31/255, green: 36/255, blue: 44/255, alpha: 1.0)
        tableView.addSubview(topView)
        
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        refreshSetup()
        
        libAPI.loadData()
        tableView.contentOffset = CGPoint(x: 0, y: searchController.searchBar.frame.size.height)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func refreshSetup() {
        refreshControl = UIRefreshControl()
        refreshControl!.tintColor = UIColor.white
        refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.white])
        refreshControl!.addTarget(self, action: #selector(ViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl!)
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        mainPageItems?.removeAll()
        self.tableView.reloadData()
        libAPI.loadData()
    }
    
    fileprivate func configureSearchBar() {
        
        let searchBar = self.searchController.searchBar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        let searchBarContainer = UIView(frame: CGRect(x: 0, y: 0, width: 600, height: 19))
        searchBarContainer.addSubview(searchBar)
        
        let views = ["searchBar" : searchBar]
        searchBarContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[searchBar]-0-|",
            options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        searchBarContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[searchBar]-0-|",
            options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        
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
        imageView.contentMode = .scaleAspectFit
        let image = UIImage(named: "logo")
        imageView.image = image
        navigationItem.titleView = imageView
    }
    
    func reloadMainPageItems(_ notification: Notification) {
        self.mainPageItems = libAPI.getMainPageItems()
        reloadTable()
    }
    
    func reloadTable() {
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
            LoadingView.shared.hideOverlayView()
            if (self.refreshControl?.isRefreshing)! {
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailViewSegue" {
            
            if let cell = sender as? ItemCell {
                let destination = segue.destination as! DetailViewController
                destination.item = cell.item
            } else if let cell = sender as? SearchResultCell {
                let destination = segue.destination as! DetailViewController
                destination.item = cell.item
                if searchController.isActive {
                    searchController.searchBar.resignFirstResponder()
                }
            }
        }
    }
    
    // MARK: Login Button actions
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        if self.isLogged {
            showLogoutDialog(self.login)
        } else {
            showLoginDialog("Log in to your account.")
        }
    }
    
    func showLoginDialog(_ message: String) {
        let myAlert = UIAlertController(title: "Log In", message: message, preferredStyle: UIAlertControllerStyle.alert)
        var loginString = ""
        var passwordString = ""
        
        myAlert.addTextField { (loginTextField) in
            
            if self.defaults.string(forKey: "login") != nil {
                loginTextField.text = self.defaults.string(forKey: "login")!
            } else {
                loginTextField.placeholder = "Login"
                loginString = loginTextField.text!
            }
        }
        
        myAlert.addTextField { (passTextField) in
            
            passTextField.isSecureTextEntry = true
            
            if self.defaults.string(forKey: "password") != nil {
                passTextField.text = self.defaults.string(forKey: "password")!
            } else {
                passTextField.placeholder = "Password"
                passwordString = passTextField.text!
            }
        }
        
        let loginAction = UIAlertAction(title: "Log In", style: UIAlertActionStyle.default) { (action) in
            
            let loginTextField = myAlert.textFields![0] as UITextField
            let passTextField = myAlert.textFields![1] as UITextField
            
            loginString = loginTextField.text!
            passwordString = passTextField.text!
            
            if self.login.isEmpty || self.password.isEmpty {
                
                if (loginString.isEmpty) || (passwordString.isEmpty) {
                    //TODO: displayAlert("All fields are required")
                    return
                }
                
                self.defaults.set(loginString, forKey: "login")
                self.defaults.set(passwordString, forKey: "password")
                self.defaults.synchronize()
                
                self.login = loginString
                self.password = passwordString
                
            }
            self.logIn()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        myAlert.addAction(loginAction)
        myAlert.addAction(cancelAction)
        
        self.present(myAlert, animated: true, completion: nil)
    }
    
    func showLogoutDialog(_ message: String) {
        let myAlert = UIAlertController(title: "Logged as:", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let logoutAction = UIAlertAction(title: "Log Out", style: UIAlertActionStyle.default) { (action) in
            self.logOut()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        myAlert.addAction(logoutAction)
        myAlert.addAction(cancelAction)
        
        self.present(myAlert, animated: true, completion: nil)
    }
    
    // MARK: TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive {
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive {
            return searchResults.count
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if searchController.isActive {
            return nil
        }
        
        let headerCell = tableView.dequeueReusableCell(withIdentifier: "customHeaderCell") as! CustomHeaderCell
        headerCell.headerLabel.text = categories[section]
        return headerCell
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchController.isActive && searchController.searchBar.text != "" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchResultCell", for: indexPath) as! SearchResultCell
            let item = searchResults[(indexPath as NSIndexPath).row]
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        return cell
    }
    
    // MARK: TableView Delegate
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TableViewCell else { return }
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: (indexPath as NSIndexPath).section)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if searchController.isActive {
            return 144.0
        } else {
            return 175.0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if searchController.isActive {
            return 0.0
        }
        return 28.0
    }
}


// MARK: Collection View
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let mainPageItemsRows = mainPageItems else {
            return 0
        }
        return mainPageItemsRows[collectionView.tag].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) as! ItemCell
        let item = mainPageItems![(collectionView.tag)][(indexPath as NSIndexPath).row]
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
    
    func updateSearchResults(for searchController: UISearchController) {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                                             selector: #selector(ViewController.performSearch), userInfo: nil, repeats: false)
        
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        footerView.isHidden = true
        refreshControl?.removeFromSuperview()
        reloadTable()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchResults.removeAll()
        searchController.isActive = false
        footerView.isHidden = false
        refreshSetup()
        reloadTable()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if  searchText.characters.count == 0 {
            searchResults.removeAll()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
        searchController.searchBar.resignFirstResponder()
    }
}
