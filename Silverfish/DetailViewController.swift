//
//  DetailViewController.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 5/12/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class DetailViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: DetailHeaderView!
    @IBOutlet weak var thumbsView: UIScrollView!

    var item: Item!
    lazy var timer = Timer()
    let contentView = UIView()
    
    override func loadView() {
        super.loadView()
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        thumbsView.addSubview(contentView)
        
        //self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[scrollView]-0-|", options: [], metrics: nil, views: ["scrollView" : thumbsView]))
        //self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[scrollView]-0-|", options: [], metrics: nil, views: ["scrollView" : thumbsView]))
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[contentView]|", options: [], metrics: nil, views: ["contentView" : contentView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[contentView]|", options: [], metrics: nil, views: ["contentView" : contentView]))
        
        //make the width of content view to be the same as that of the containing view.
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[contentView(==thumbsView)]", options: [], metrics: nil, views: ["contentView" : contentView, "thumbsView" : thumbsView]))
        
        self.view.contentMode = UIViewContentMode.redraw
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = item.itemTitle
        
        headerView.nameLabel.text = item.name
        
        if item.altName != nil {
            headerView.altNameLabel.text = item.altName
        } else {
            headerView.altNameLabel.text = item.name
        }
        
        let pView = ItemView(frame: headerView.posterView.bounds, posterURL: item.itemPoster!)
        headerView.posterView.addSubview(pView)
        
        headerView.contentMode = .redraw
        
        configureTableView()
        setContentForSlideshow()
        
        if item.thumbsUrl?.count > 1 {
            timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.moveToNextPage), userInfo: nil, repeats: true)
        }
    }
    
    deinit {
        timer.invalidate()
    }
    
    func moveToNextPage() {
        
        let pageWidth:CGFloat = self.view.frame.width
        let maxWidth:CGFloat = pageWidth * CGFloat((item.thumbsUrl?.count)!)
        let contentOffset:CGFloat = self.thumbsView.contentOffset.x
        
        var slideToX = contentOffset + pageWidth
        
        if  contentOffset + pageWidth == maxWidth{
            slideToX = 0
        }
        self.thumbsView.scrollRectToVisible(CGRect(x: slideToX, y: 0, width: pageWidth, height: self.thumbsView.frame.height), animated: true)
    }
    
    func configureTableView() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 175.0
    }

    func setContentForSlideshow() {
        thumbsView.translatesAutoresizingMaskIntoConstraints = false
        thumbsView.addSubview(contentView)
        
        if let thumbs = item.thumbsUrl {
            
            var viewsDict = [String: UIView]()
            viewsDict["contentView"] = contentView
            viewsDict["super"] = self.view
            var horizontal_constraints = "H:|"
            
            for thumb in thumbs {
                let thView = UIImageView()
                thView.downloadedFrom(thumb)
                thView.translatesAutoresizingMaskIntoConstraints = false
                thView.contentMode = .scaleAspectFill
                viewsDict["subview_\(thumbs.index(of: thumb)!)"] = thView
                contentView.addSubview(thView)
                
                horizontal_constraints += "[subview_\(thumbs.index(of: thumb)!)(==\(self.view.frame.width))]"
                contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subview_\(thumbs.index(of: thumb)!)(==\(thumbsView.frame.height))]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict))
            }
            
            horizontal_constraints += "|"
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: horizontal_constraints, options: NSLayoutFormatOptions.alignAllTop, metrics: nil, views: viewsDict))
        }
        
        thumbsView.contentSize = contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
    }
    
    func thumbsSet() {
        if item.thumbsUrl != nil {
            let thumbs = item.thumbsUrl!
            
            for thumb in thumbs {
                let frame = CGRect(x: self.view.frame.width * CGFloat(thumbs.index(of: thumb)!), y: 0, width: self.view.frame.width, height: thumbsView.frame.height)
                addSlide(frame, imageUrl: thumb)
            }
            self.thumbsView.contentSize = CGSize(width: self.view.frame.width*CGFloat(item.thumbsUrl!.count), height: thumbsView.frame.height)

        } else {
            let frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: thumbsView.frame.height)
            let thImage = getBiggerThumbLink(item.itemPoster!, sizeIndex: "1")
            addSlide(frame, imageUrl: thImage)
            thumbsView.isScrollEnabled = false
        }
    }
    
    func addSlide(_ frame: CGRect, imageUrl: String) {
        let thView = ItemView(frame: frame, posterURL: imageUrl)
        thView.translatesAutoresizingMaskIntoConstraints = true
        thView.contentMode = .scaleAspectFill
        thumbsView.addSubview(thView)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

    }
}

// MARK: Table View
extension DetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if item.similarItems != nil {
            if !item.similarItems!.isEmpty {
                return 3
            }
            return 2
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCell(withIdentifier: "customHeaderCell") as! CustomHeaderCell
        switch (section) {
        case 0:
            headerCell.headerLabel.text = "Details"
        case 1:
            headerCell.headerLabel.text = "Plot"
        case 2:
            headerCell.headerLabel.text = "More Like This"
        default:
            return nil
        }
        return headerCell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch ((indexPath as NSIndexPath).section) {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailsCell", for: indexPath) as! DetailsCell
            cell.yearLabel.text = item.year
            cell.genreLabel.text = item.genre
            cell.ratingBar.progress = item.ratingValue!
            cell.upVoteLabel.text = item.upVoteValue!
            cell.downVoteLabel.text = item.downVoteValue!
            cell.countryLabel.text = item.country
            cell.directorsName.text = item.director
            cell.actorsName.text = item.actors
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "descriptionCell", for: indexPath) as! DescriptionCell
            cell.descriptionLabel.text = item.itemDescription
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "similarItemsCell", for: indexPath) as! TableViewCell
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            return cell
        }
    }
}

extension DetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TableViewCell else { return }
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: (indexPath as NSIndexPath).section)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch ((indexPath as NSIndexPath).section) {
        case 0:
            return UITableViewAutomaticDimension
        case 1:
            return UITableViewAutomaticDimension
        case 2:
            return 175.0
        default:
            return 44.0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch (section) {
        case 0:
            return 0
        case 1:
            return 0
        default:
            return 28.0
        }
    }
}

// MARK: Collection View
extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return item.similarItems!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) as! ItemCell
        let item = self.item.similarItems![(indexPath as NSIndexPath).row]

        let view = ItemView(frame: cell.bounds, posterURL: item.itemPoster!)
        cell.addSubview(view)
        
//        cell.posterView.image = nil
//        cell.posterView.downloadedFrom(item.itemPoster!)
        
        if !item.hasDetails {
            LibraryAPI.sharedInstance.getItemDetails(item)
        }
        
        cell.item = item
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.item.similarItems![(indexPath as NSIndexPath).row]
        
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "detailViewController") as! DetailViewController
        controller.title = item.itemTitle
        controller.item = item
        self.navigationController?.pushViewController(controller, animated: true)
    }
}

