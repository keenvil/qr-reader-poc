//
//  UserProfileViewController.swift
//  qr-reader-poc
//
//  Created by Esteban Abait on 5/30/16.
//  Copyright © 2016 my-community. All rights reserved.
//

import Foundation
import UIKit

class UserProfileViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  @IBAction func back(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  
}
