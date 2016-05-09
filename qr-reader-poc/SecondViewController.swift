//
//  SecondViewController.swift
//  qr-reader-poc
//
//  Created by Franco Monsalvo on 5/6/16.
//  Copyright © 2016 my-community. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Alamofire

class SecondViewController: UIViewController {
 
  @IBOutlet weak var firstNameLabel: UILabel!
  @IBOutlet weak var lastNameLabel: UILabel!
  @IBOutlet weak var genderLabel: UILabel!
  @IBOutlet weak var documentLabel: UILabel!
  
  var userID = ""
  var userHash = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    Alamofire.request(.GET, "https://httpbin.org/get", parameters: ["foo": "bar"])
      .responseJSON { response in
        print(response.result)   // result of response serialization
        
        if let JSON = response.result.value {
          print("JSON: \(JSON)")
        }
    }
    
    print("DETAIL UserID: " + userID)
    print("DETAIL UserHash: " + userHash)
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
    
}

