//
//  ViewController.swift
//  azell-azzBook
//
//  Created by Marcel Canhisares on 26/01/16.
//  Copyright © 2016 Azell. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

class ViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
    }
    
    @IBAction func fbBtnPressed(sender: UIButton) {
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logInWithReadPermissions(["email"]) { (facebookResult:FBSDKLoginManagerLoginResult!, facebookError:NSError!) -> Void in
            if facebookError != nil{
                print("Facebook login failed. Error \(facebookError)")
            } else if facebookResult.isCancelled {
                print("Facebook login was cancelled.")
            } else {
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                DataService.ds.REF_BASE.authWithOAuthProvider("facebook", token: accessToken,
                    withCompletionBlock: { error, authData in
                        if error != nil {
                            print("Login failed. \(error)")
                        } else {
                            //this is a dictionary. Do not unwrap, always do if lets. This is not right.
                            let user = ["provider": authData.provider!]
                            DataService.ds.createFirebaseUser(authData.uid, user: user)
                            
                            NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                        }
                })
            }
        }
    }
    
    @IBAction func attemptLogin(sender: UIButton!){
        if let email = emailField.text where email != "", let pwd = passwordField.text where pwd != "" {
            DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { error, authData in
                if error != nil {
                    switch error.code {
                    case STATUS_ACCOUNT_NONEXIST:
                            DataService.ds.REF_BASE.createUser(email, password: pwd, withValueCompletionBlock: { error, result in
                                if error != nil {
                                    self.showErrorAlert("Could not create account", msg: "Problem creating account. Try something else")
                                    //TODO
                                    //Do other error handling here (email already exists in database, password not long enough
                                    //Check for errors in firebase documentation
                                } else {
                                    NSUserDefaults.standardUserDefaults().setValue(result[KEY_UID],forKey: KEY_UID)
                                    DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: nil)
                                    DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { err, authData in
                                        let user = ["provider": authData.provider!]
                                        DataService.ds.createFirebaseUser(authData.uid, user: user)
                                    })
                                    self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                                }
                            })
                    case STATUS_INVALID_PASSWORD:
                        self.showErrorAlert("Login Error", msg: "Error logging in, check username and password")
                    //TODO 
                    //CHECK OTHER ERROR CODES IN FIREBASE DOCUMENTATION
                    default:
                        self.showErrorAlert("Login Error", msg: "Error logging in, contact support")
                    }
                } else {
                    NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                    self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                }
            })
        } else {
            showErrorAlert("Email and Password Required", msg: "You must enter an email and a pasword")
        }
    }
    
    func showErrorAlert (title: String, msg: String){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
    


}

