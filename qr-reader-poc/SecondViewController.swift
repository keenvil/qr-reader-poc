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

/*
 Nro Tramite
 Apellido (ambos separados por un espacio)
 Nombre
 Sexo (M / F)
 DNI
 Ejemplar
 Fecha Nacimiento (DD/MM/AAAA)
 Fecha Emisión (DD/MM/AAAA)
 */

class SecondViewController: UIViewController {
 
  @IBOutlet weak var firstNameLabel: UILabel!
  @IBOutlet weak var lastNameLabel: UILabel!
  @IBOutlet weak var genderLabel: UILabel!
  @IBOutlet weak var documentLabel: UILabel!
  @IBOutlet weak var avatarImage: UIImageView!
  
  var userData: [String] = ["", "Abait", "Esteban Sait", "F", "30650388"]
  
  override func viewDidLoad() {
    super.viewDidLoad()

    lastNameLabel.text = isLatestDocumentSchema() ? userData[1] : userData[3]
    firstNameLabel.text = isLatestDocumentSchema() ? userData[2] : userData[4]
    genderLabel.text = getGender()
    documentLabel.text = isLatestDocumentSchema() ? userData[4] : userData[0]
    
    if let url = NSURL(string: userData[userData.count-1]) {
      if let data = NSData(contentsOfURL: url) {
        avatarImage.image = UIImage(data: data)
      }
    }
    
    avatarImage.layer.borderWidth = 4
    avatarImage.layer.borderColor = UIColor.whiteColor().CGColor
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  @IBAction func cancel(sender: AnyObject) {
    dismissViewControllerAnimated(false, completion: nil)
  }
  
  func isLatestDocumentSchema() -> Bool {
    return userData.count <= 9
  }
  
  func getGender() -> String {
    let genderChar = isLatestDocumentSchema() ? userData[3] : userData[7]
    return genderChar == "M" ? "Masculino" : "Femenino"
  }
  

}

