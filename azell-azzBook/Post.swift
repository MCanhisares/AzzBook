//
//  Post.swift
//  azell-azzBook
//
//  Created by Marcel Canhisares on 03/02/16.
//  Copyright © 2016 Azell. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class Post {
    private var _postDescription: String?
    private var _imgUrl: String?
    private var _likes: Int!
    private var _username: String!
    private var _postKey: String!
    private var _postRef: Firebase!
    
    var postDescription: String? {
        return _postDescription
    }
    
    var imgUrl: String? {
        return _imgUrl
    }
    
    var likes: Int {
        return _likes
    }
    
    var username: String {
        return _username
    }
    
    var postKey: String {
        return _postKey
    }
    
    init(description: String?, imgUrl: String?, username: String) {
        self._postDescription = description
        self._imgUrl = imgUrl
        self._username = username
    }
    
    init(postKey: String, dictionary: Dictionary<String, AnyObject>) {
        self._postKey = postKey
        
        if let likes = dictionary["likes"] as? Int {
            self._likes = likes
        }
        
        if let imgUrl = dictionary["imgUrl"] as? String {
            self._imgUrl = imgUrl
        }
        
        if let desc = dictionary["description"] as? String {
            self._postDescription = desc
        }
        
        self._postRef = DataService.ds.REF_POSTS.childByAppendingPath(self._postKey)
    }
    
    func adjustLikes(addLike: Bool) {
        
        if addLike {
            _likes = _likes + 1
        } else {
            _likes = _likes - 1
        }
        
        //Save the new total likes to firebase
        _postRef.childByAppendingPath("likes").setValue(_likes)
        
    }
    
    
    
}