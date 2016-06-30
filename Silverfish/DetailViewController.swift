//
//  DetailViewController.swift
//  Silverfish
//
//  Created by Maxim Ryazanov on 5/12/16.
//  Copyright © 2016 Givno Inc. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: DetailHeaderView!
    @IBOutlet weak var thumbsView: UIScrollView!

    var item: Item!
    lazy var timer = NSTimer()
    let contentView = UIView()
    
    override func loadView() {
        super.loadView()
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        thumbsView.addSubview(contentView)
        
        //self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[scrollView]-0-|", options: [], metrics: nil, views: ["scrollView" : thumbsView]))
        //self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[scrollView]-0-|", options: [], metrics: nil, views: ["scrollView" : thumbsView]))
        
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: [], metrics: nil, views: ["contentView" : contentView]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView]|", options: [], metrics: nil, views: ["contentView" : contentView]))
        
        //make the width of content view to be the same as that of the containing view.
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[contentView(==thumbsView)]", options: [], metrics: nil, views: ["contentView" : contentView, "thumbsView" : thumbsView]))
        
        self.view.contentMode = UIViewContentMode.Redraw
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
        
        headerView.contentMode = .Redraw
        
        configureTableView()
        setContentForSlideshow()
        
        if item.thumbsUrl?.count > 1 {
            timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(self.moveToNextPage), userInfo: nil, repeats: true)
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
        self.thumbsView.scrollRectToVisible(CGRectMake(slideToX, 0, pageWidth, CGRectGetHeight(self.thumbsView.frame)), animated: true)
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
                thView.contentMode = .ScaleAspectFill
                viewsDict["subview_\(thumbs.indexOf(thumb)!)"] = thView
                contentView.addSubview(thView)
                
                horizontal_constraints += "[subview_\(thumbs.indexOf(thumb)!)(==\(self.view.frame.width))]"
                contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[subview_\(thumbs.indexOf(thumb)!)(==\(thumbsView.frame.height))]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict))
            }
            
            horizontal_constraints += "|"
            contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(horizontal_constraints, options: NSLayoutFormatOptions.AlignAllTop, metrics: nil, views: viewsDict))
        }
        
        thumbsView.contentSize = contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
    }
    
    func thumbsSet() {
        if item.thumbsUrl != nil {
            let thumbs = item.thumbsUrl!
            
            for thumb in thumbs {
                let frame = CGRect(x: self.view.frame.width * CGFloat(thumbs.indexOf(thumb)!), y: 0, width: self.view.frame.width, height: thumbsView.frame.height)
                addSlide(frame, imageUrl: thumb)
            }
            self.thumbsView.contentSize = CGSizeMake(self.view.frame.width*CGFloat(item.thumbsUrl!.count), thumbsView.frame.height)

        } else {
            let frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: thumbsView.frame.height)
            let thImage = getBiggerThumbLink(item.itemPoster!, sizeIndex: "1")
            addSlide(frame, imageUrl: thImage)
            thumbsView.scrollEnabled = false
        }
    }
    
    func addSlide(frame: CGRect, imageUrl: String) {
        let thView = ItemView(frame: frame, posterURL: imageUrl)
        thView.translatesAutoresizingMaskIntoConstraints = true
        thView.contentMode = .ScaleAspectFill
        thumbsView.addSubview(thView)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

    }
}

// MARK: Table View
extension DetailViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if item.similarItems != nil {
            if !item.similarItems!.isEmpty {
                return 3
            }
            return 2
        }
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCellWithIdentifier("customHeaderCell") as! CustomHeaderCell
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section) {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("detailsCell", forIndexPath: indexPath) as! DetailsCell
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
            let cell = tableView.dequeueReusableCellWithIdentifier("descriptionCell", forIndexPath: indexPath) as! DescriptionCell
            cell.descriptionLabel.text = item.itemDescription
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("similarItemsCell", forIndexPath: indexPath) as! TableViewCell
            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
            return cell
        }
    }
}

extension DetailViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let tableViewCell = cell as? TableViewCell else { return }
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.section)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch (indexPath.section) {
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
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return item.similarItems!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("itemCell", forIndexPath: indexPath) as! ItemCell
        let item = self.item.similarItems![indexPath.row]

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
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let item = self.item.similarItems![indexPath.row]
        
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("detailViewController") as! DetailViewController
        controller.title = item.itemTitle
        controller.item = item
        self.navigationController?.pushViewController(controller, animated: true)
    }
}

