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

class SecondViewController: UIViewController {
 
  @IBOutlet weak var firstNameLabel: UILabel!
  @IBOutlet weak var lastNameLabel: UILabel!
  @IBOutlet weak var genderLabel: UILabel!
  @IBOutlet weak var documentLabel: UILabel!
  
  var userData: [String] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()

    
    self.firstNameLabel.text = userData[1]
    self.lastNameLabel.text = userData[2]
    //self.genderLabel.text = gender
    self.documentLabel.text = userData[4]
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  @IBAction func cancel(sender: AnyObject) {
    self.dismissViewControllerAnimated(false, completion: nil)
  }

}

