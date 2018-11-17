//
//  SMImageModel.swift
//  SMPhotos
//
//  Created by Sudhir Madaan on 12/11/18.
//  Copyright © 2018 SM. All rights reserved.
//

import UIKit

class SMImageModel: Codable {
    
    enum CurrState: Int, Codable {
        case downloaded = 0, failed
    }
    
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title:String
    var currState:CurrState?
    
    //Unused values
    //    let ispublic: Int
    //    let isfriend: Int
    //    let isfamily: Int
    
    var imageURL:URL? {
        get {
            //http://farm{farm}.static.flickr.com/{server}/{id}_{secret}.jpg
            let urlString = "https://farm\(farm).static.flickr.com/\(server)/\(id)_\(secret).jpg"
            return URL.init(string: urlString)
        }
    }
}

class SMSearchAPIResponse: Codable {
    let photos: SMRemotePhotos?
    
    //Unused values
    //let stat: String
    
    class SMRemotePhotos: Codable {
        let photo:[SMImageModel]?
        //Unused values
        //    let page: Int
        //    let pages: Int
        //    let perpage: Int
        //    let total: String
    }
}
