//
//  SMImageCollectionViewController.swift
//  SMPhotos
//
//  Created by Sudhir Madaan on 12/11/18.
//  Copyright © 2018 SM. All rights reserved.
//

import UIKit

fileprivate let reuseIdentifier = "Image Collection View Cell"
fileprivate let inset: CGFloat = 10
fileprivate let minimumLineSpacing: CGFloat = 10
fileprivate let minimumInteritemSpacing: CGFloat = 10
fileprivate let cellsPerRow = 3

class SMImageCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var imageModels:[SMImageModel]?
    
    lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download queue"
        return queue
    }()
    lazy var downloadsInProgress: [IndexPath: Operation] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            collectionView?.contentInsetAdjustmentBehavior = .always
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (imageModels != nil) ? imageModels!.count : 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? SMImageCollectionViewCell
            else
        {
            fatalError("SMImageCollectionViewCell not found")
        }
        
        cell.lblStatus.isHidden = true
        
        let currImageModel = imageModels![indexPath.row]
        if let currState = currImageModel.currState
        {
            cell.activityIndicatorView.stopAnimating()
            switch currState
            {
            case .downloaded:
                //Load from cache, if present
                if let imageURL = currImageModel.imageURL,
                    let cachedImage = sharedImageCache.object(forKey: imageURL.absoluteString as NSString)
                {
                    cell.imageView.image = cachedImage
                }
                else
                {
                    //Removed from cache, download again
                    currImageModel.currState = nil
                    configure(cell: cell, forNew: currImageModel, at: indexPath)
                }
                
            default:
                cell.imageView.image = nil
                cell.lblStatus.isHidden = false
                cell.lblStatus.text = NSLocalizedString("title_unable_to_load", comment: "Unable to load")
            }
            
        }
        else
        {
            //New
            configure(cell: cell, forNew: currImageModel, at: indexPath)
        } //if
        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return minimumLineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return minimumInteritemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var marginsAndInsets:CGFloat = 0
        if #available(iOS 11.0, *) {
            marginsAndInsets = inset * 2 + collectionView.safeAreaInsets.left + collectionView.safeAreaInsets.right + minimumInteritemSpacing * CGFloat(cellsPerRow - 1)
        } else {
            marginsAndInsets = inset * 2 + collectionView.layoutMargins.left + collectionView.layoutMargins.right + minimumInteritemSpacing * CGFloat(cellsPerRow - 1)
        }
        
        let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(cellsPerRow)).rounded(.down)
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    //MARK: Scrolling methods
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        downloadQueue.isSuspended = true
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        if !decelerate && downloadQueue.isSuspended
        {
            loadImagesForDisplayedCellItems()
            downloadQueue.isSuspended = false
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if downloadQueue.isSuspended
        {
            loadImagesForDisplayedCellItems()
            downloadQueue.isSuspended = false
        }
    }
    
    //MARK: Helpers
    
    private func configure(cell:SMImageCollectionViewCell, forNew imageModel:SMImageModel, at indexPath:IndexPath) {
        cell.imageView.image = nil
        cell.activityIndicatorView.startAnimating()
        
        if !collectionView.isDragging && !collectionView.isDecelerating
        {
            startDownload(for: imageModel, at: indexPath)
        }
    }
    
    private func loadImagesForDisplayedCellItems()
    {
        let visibleItems = collectionView.indexPathsForVisibleItems
        let visiblePaths = Set(visibleItems)
        
        let allPendingOperations = Set(downloadsInProgress.keys)
        var toBeCancelled = allPendingOperations
        toBeCancelled.subtract(visiblePaths)
        
        var toBeStarted = visiblePaths
        toBeStarted.subtract(allPendingOperations)
        
        //Remove previous operations which are not required currently
        for indexPath in toBeCancelled
        {
            if let pendingDownload = downloadsInProgress[indexPath] {
                pendingDownload.cancel()
            }
            downloadsInProgress.removeValue(forKey: indexPath)
        }
        
        //Add new operations
        for indexPath in toBeStarted
        {
            let recordToProcess = imageModels![indexPath.row]
            if let currState = recordToProcess.currState,
                currState == .downloaded
            {
                continue
            } //if
            startDownload(for: recordToProcess, at: indexPath)
        } //if
    }
    
    private func startDownload(for currImage: SMImageModel, at indexPath: IndexPath) {
        guard downloadsInProgress[indexPath] == nil else {
            return
        }
        
        let downloadOp = SMImageDownloadOperation.init(currImage)
        downloadOp.completionBlock = {
            DispatchQueue.main.async {
                self.downloadsInProgress.removeValue(forKey: indexPath)
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
        downloadQueue.addOperation(downloadOp)
        downloadsInProgress[indexPath] = downloadOp
    }
    
    //MARK: Others
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    deinit
    {
        print("In deinit")
        downloadQueue.cancelAllOperations()
    }
}

