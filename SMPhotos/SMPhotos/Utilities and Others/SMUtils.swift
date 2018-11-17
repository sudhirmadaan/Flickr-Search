//
//  SMUtils.swift
//  SMPhotos
//
//  Created by Sudhir Madaan on 12/11/18.
//  Copyright © 2018 SM. All rights reserved.
//

import Foundation
import UIKit

let sharedImageCache = NSCache<NSString, UIImage>()

extension UIViewController {
    
    func showSimpleAlertWith(title: String?, message:String?)
    {
        let alertVC: UIAlertController = UIAlertController(title: title ?? "", message: message ?? "", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction.init(title: NSLocalizedString("title_Ok", comment: "Ok"), style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
    
    func showNoNetworkError()
    {
        showSimpleAlertWith(title: NSLocalizedString("title_Oops", comment: "Oops"), message: NSLocalizedString("msg_no_internet", comment: "No internet connection found"))
    }
}

extension NSError {
    
    func isNetworkConnectionError() -> Bool
    {
        if (domain == NSURLErrorDomain)
        {
            let networkErrors = [NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet]
            return networkErrors.contains(code)
        } //if
        return false
    }
}
