//
//  SMImageDownloadOperation.swift
//  SMPhotos
//
//  Created by Sudhir Madaan on 12/11/18.
//  Copyright © 2018 SM. All rights reserved.
//

import UIKit

class SMImageDownloadOperation: Operation {
    let imageModel: SMImageModel
    var image:UIImage?
    
    init(_ imageModel: SMImageModel) {
        self.imageModel = imageModel
    }
    
    override func main()
    {
        if isCancelled {
            return
        }
  
        guard let imageURL = imageModel.imageURL,
            let imageData = try? Data(contentsOf: imageURL) else {
                imageModel.currState = SMImageModel.CurrState.failed
            return
        }

        if isCancelled {
            return
        }
        
        if !imageData.isEmpty,
            let currImage = UIImage(data:imageData)
        {
            sharedImageCache.setObject(currImage, forKey: imageURL.absoluteString as NSString)
            imageModel.currState = SMImageModel.CurrState.downloaded
        }
        else
        {
            imageModel.currState = SMImageModel.CurrState.failed
        }
    }
}
