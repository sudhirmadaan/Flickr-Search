//
//  SMPhotosTests.swift
//  SMPhotosTests
//
//  Created by Sudhir Madaan on 11/11/18.
//  Copyright © 2018 SM. All rights reserved.
//

import XCTest
@testable import SMPhotos

var navVC:UINavigationController!

class SMPhotosTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        navVC = UIStoryboard(name: "Main",
                             bundle: nil).instantiateInitialViewController() as? UINavigationController
    }
    
    override func tearDown() {
        navVC = nil
        super.tearDown()
    }
    
    func testSearchCriteria() {
        
        let searchController = navVC.children[0] as! SMSearchViewController
        XCTAssertNil(searchController.sanitizedSearchCriteriaFor(text: " "))
        XCTAssertNil(searchController.sanitizedSearchCriteriaFor(text: ""))
        XCTAssertEqual(searchController.sanitizedSearchCriteriaFor(text: "AB"), "ab")
        XCTAssertEqual(searchController.sanitizedSearchCriteriaFor(text: " 123 "), "123")
        XCTAssertEqual(searchController.sanitizedSearchCriteriaFor(text: " A+1 "), "a%2B1")
    }
    
    func testValidInputInSearchBar() {
        
        let searchController = navVC.children[0] as! SMSearchViewController
        XCTAssertTrue(searchController.isValidInputInSearchBar(text: ""))
        XCTAssertTrue(searchController.isValidInputInSearchBar(text: " "))
        XCTAssertTrue(searchController.isValidInputInSearchBar(text: "\n"))
        
        //Ideally use inverse of expected strings
        XCTAssertFalse(searchController.isValidInputInSearchBar(text: "\\"))
        XCTAssertFalse(searchController.isValidInputInSearchBar(text: ";"))
        XCTAssertFalse(searchController.isValidInputInSearchBar(text: "/"))
    }
    
    func testURLForSearchCriteria() {
        
        let searchController = navVC.children[0] as! SMSearchViewController
        let url = searchController.urlForSearchCriteria(text: "kittens")
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.absoluteString, "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=3e7cc266ae2b0e0d78e279ce8e361736&text=kittens&format=json&nojsoncallback=1&safe_search=1")
    }
    
    func testSearchCallForSuccess() {
        let searchController = navVC.children[0] as! SMSearchViewController
        let url = searchController.urlForSearchCriteria(text: "flowers")!
        
        let promise = expectation(description: "Success")
        searchController.startSearchWith(url: url, completionHandler: {resultStatus, allImageModels in
            
            if (resultStatus == .noError)
            {
                XCTAssertNotNil(allImageModels)
                promise.fulfill()
            }
        })
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSearchCallForPerformance() {
        let searchController = navVC.children[0] as! SMSearchViewController
        let url:URL = searchController.urlForSearchCriteria(text: "kittens")!

        self.measure {
            searchController.startSearchWith(url: url, completionHandler: {resultStatus, allImageModels in
            })
        }
    }
}
