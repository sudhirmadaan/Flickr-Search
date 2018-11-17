//
//  SMSearchViewController.swift
//  SMPhotos
//
//  Created by Sudhir Madaan on 12/11/18.
//  Copyright © 2018 SM. All rights reserved.
//

import UIKit

fileprivate let searchAPI = "https://api.flickr.com/services/rest/"

class SMSearchViewController: UIViewController {
    
    enum NetworkCallResult {
        case noError, internetError, genericError
    }
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicatorView.isHidden = true
        searchBar.accessibilityIdentifier = "Search Bar"
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    //MARK:- Helpers
    func sanitizedSearchCriteriaFor(text: String?)->String?
    {
        guard let searchText = text?.trimmingCharacters(in: .whitespaces).lowercased() else {
            return nil
        }
        
        if (searchText.count > 0)
        {
            //Only use alphanumerics and spaces for now
            var allowedCharacterSet = CharacterSet.alphanumerics
            allowedCharacterSet.insert(" ")
            
            var sanitizedText = searchText.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
            sanitizedText = sanitizedText?.replacingOccurrences(of: " ", with: "+")
            return sanitizedText
        } //if
        
        return nil
    }
    
    func isValidInputInSearchBar(text: String) -> Bool {
        if (text == "") || (text == "\n") {
            return true
        }
        
        var allowedCharacterSet = CharacterSet.alphanumerics
        allowedCharacterSet.insert(" ")
        return (text.rangeOfCharacter(from: allowedCharacterSet) != nil)
    }
    
    func urlForSearchCriteria(text:String) -> URL? {
        
        guard var components = URLComponents(string:searchAPI) else {
            return nil
        }
        
        //Create query
        //Shared keys
        components.query = "method=flickr.photos.search&api_key=3e7cc266ae2b0e0d78e279ce8e361736&text=\(text)&format=json&nojsoncallback=1&safe_search=1"
        
        //Custom keys
        //            components.query = "method=flickr.photos.search&api_key=3701b8c31cec9ce00befd12653030ca5&text=\(text)&format=json&nojsoncallback=1&api_sig=5d62376733eef3d8beb7a28b7d95a39d"
        
        return components.url
    }
    
    func startSearchWith(url: URL, completionHandler: @escaping (_ resultStatus:NetworkCallResult,_ allImageModels:[SMImageModel]?)->Void)
    {
        let task = URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
            
            var resultStatus:NetworkCallResult = .genericError
            var allImageModels:[SMImageModel]?
            
            if let currError = error as NSError?
            {
                if currError.isNetworkConnectionError()
                {
                    resultStatus = .internetError
                }
            }
            else
            {
                if let statusCode = (response as? HTTPURLResponse)?.statusCode,
                    statusCode == 200,
                    let currData = data
                {
                    do
                    {
                        let decoder = JSONDecoder()
                        let apiResponse = try decoder.decode(SMSearchAPIResponse.self, from: currData)
                        allImageModels = apiResponse.photos?.photo
                        resultStatus = .noError
                    }
                    catch let error
                    {
                        print(error.localizedDescription)
                    }
                }
            }
            completionHandler(resultStatus, allImageModels)
        })
        task.resume()
    }
    
    fileprivate func setupUIForSearch(isNotSearching:Bool = true)
    {
        if isNotSearching
        {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            searchBar.isUserInteractionEnabled = true
            activityIndicatorView.stopAnimating()
            activityIndicatorView.isHidden = true
        }
        else
        {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            searchBar.isUserInteractionEnabled = false
            activityIndicatorView.isHidden = false
            activityIndicatorView.startAnimating()
        }
    }
}

extension SMSearchViewController : UISearchBarDelegate
{
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        return isValidInputInSearchBar(text: text)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.endEditing(true)
        if let searchText = sanitizedSearchCriteriaFor(text: searchBar.text)
        {
            guard let url = urlForSearchCriteria(text: searchText) else {
                showSimpleAlertWith(title: NSLocalizedString("title_Oops", comment: "Oops"), message: NSLocalizedString("msg_err_generic", comment: "Generic error"))
                return
            }
            
            //Set up UI elements
            setupUIForSearch(isNotSearching: false)
            startSearchWith(url: url, completionHandler: {resultStatus, allImageModels in
                
                DispatchQueue.main.async {
                    
                    self.setupUIForSearch()
                    switch resultStatus
                    {
                    case .genericError:
                        self.showSimpleAlertWith(title: NSLocalizedString("title_Oops", comment: "Oops"), message: NSLocalizedString("msg_err_generic", comment: "Generic error"))
                        
                    case .internetError:
                        self.showSimpleAlertWith(title: NSLocalizedString("title_Oops", comment: "Oops"), message: NSLocalizedString("msg_no_internet", comment: "No internet"))
                        
                    default:
                        if let imageModels = allImageModels,
                            imageModels.count > 0
                        {
                            guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Image Collection View Controller") as? SMImageCollectionViewController
                                else
                            {
                                fatalError("Image Collection View Controller not found")
                            }
                            viewController.imageModels = imageModels
                            viewController.title = self.searchBar.text
                            self.navigationController?.pushViewController(viewController, animated: true)
                        }
                        else
                        {
                            self.showSimpleAlertWith(title: NSLocalizedString("title_Oops", comment: "Oops"), message: NSLocalizedString("msg_no_data", comment: "No data"))
                        }
                    }
                }
            })
        }
        else
        {
            //Show alert
            showSimpleAlertWith(title: nil, message: NSLocalizedString("msg_empty_text", comment: "Please enter your search criteria."))
        }
    }
}
