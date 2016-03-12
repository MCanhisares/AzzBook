//
//  FeedVC.swift
//  azell-azzBook
//
//  Created by Marcel Canhisares on 29/01/16.
//  Copyright © 2016 Azell. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageSelectorImg: UIImageView!
    @IBOutlet weak var postField: MaterialTextField!
    @IBOutlet weak var tableView: UITableView!
    var posts = [Post]()
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    static var imageCache = NSCache()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.estimatedRowHeight = 407
        imageSelectorImg.layer.cornerRadius = 2.0
        imageSelectorImg.clipsToBounds = true
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        initObservers()
        
    }
    
    func initObservers() {
        
        DataService.ds.REF_POSTS.observeEventType(.Value, withBlock: { snapshot in
            
            if let snapshots = snapshot.children.allObjects as? [FDataSnapshot] {
                self.posts = []
                for snap in snapshots {
                    print("SNAP:\(snap)")
                    
                    //Clear the array because we are going to add all the objects again
                    
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        
                        let post = Post(postKey: key, dictionary: postDict)
                        self.posts.append(post)
                    }
                }
                
                self.tableView.reloadData()
            }
        })
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            
            //Cancel the image request when cellForRowAtIndexPath is called because it means
            //we need to recycle the cell and we need the old request to stop downloading the image
            //cell.request?.cancel()
            
            let post = self.posts[indexPath.row]
            
            //Declare an empty image variable
            var img: UIImage?
            
            //If there is a url for an image, try and get it from the local cache first
            //before we attempt to download it
            if let url = post.imgUrl {
                img = FeedVC.imageCache.objectForKey(url) as? UIImage
            }
            
            cell.configureCell(post, img: img)
            
            return cell
            
        } else {
            
            return PostCell()
        }

    }

    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = self.posts[indexPath.row]
        
        if post.imgUrl == nil {
            return 200
        } else {
            return tableView.estimatedRowHeight
        }
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelectorImg.image = image
        imageSelectorImg.alpha = 1.0
        imageSelected = true
    }
    
    @IBAction func selectImage(sender: UITapGestureRecognizer) {
        presentViewController(imagePicker, animated: true, completion: nil)
        imageSelectorImg.alpha = 0.5
    }
    @IBAction func makePost(sender: MaterialButton) {
        if let txt = postField.text where txt != "" {
            
            if let img = imageSelectorImg.image {
                let urlStr = "https://post.imageshack.us/upload_api.php"
                let url = NSURL(string: urlStr)!
                let imgData = UIImageJPEGRepresentation(img, 0.2)!
                
                let keyData = "49ACILMSa3bb4f31c5b6f7aeee9e5623c70c83d7".dataUsingEncoding(NSUTF8StringEncoding)!
                let keyJSON = "json".dataUsingEncoding(NSUTF8StringEncoding)!
                
                
                Alamofire.upload(.POST, url, multipartFormData: { multipartFormData in
                    
                    multipartFormData.appendBodyPart(data: imgData, name:"fileupload", fileName:"image", mimeType: "image/jpg")
                    multipartFormData.appendBodyPart(data: keyData, name: "key")
                    multipartFormData.appendBodyPart(data: keyJSON, name: "format")
                    
                    }) { encodingResult in
                        
                        switch encodingResult {
                        case .Success(let upload, _, _):
                            upload.responseJSON(completionHandler: { response in
                                if let info = response.result.value as? Dictionary<String, AnyObject> {
                                    
                                    if let links = info["links"] as? Dictionary<String, AnyObject> {
                                        print(links)
                                        if let imgLink = links["image_link"] as? String {
                                            self.postToFirebase(imgLink)
                                        }
                                    }
                                }
                            })
                            
                        case .Failure(let error):
                            print(error)
                            //Maybe show alert to user and let them try again
                        }
                }
            } else {
                postToFirebase(nil)
            }
            
            
        }

    }
    
    func postToFirebase(imgUrl: String?){
        var post: Dictionary<String, AnyObject> = [
            "description":postField.text!,
            "likes": 0
        ]
        
        if imgUrl != nil {
            post["imgUrl"] = imgUrl!
        }
        
        //Save new post to firebase
        let fbPost = DataService.ds.REF_POSTS.childByAutoId()
        fbPost.setValue(post)
        
        //Clear out fields
        self.postField.text = ""
        self.imageSelectorImg.image = UIImage(named: "camera")
        
        tableView.reloadData()
    }
    
}
