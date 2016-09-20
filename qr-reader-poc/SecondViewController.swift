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
    
    avatarImage.image = selectAvatar()
    
    avatarImage.layer.borderWidth = 4
    avatarImage.layer.borderColor = UIColor.white.cgColor
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  @IBAction func cancel(_ sender: AnyObject) {
    dismiss(animated: false, completion: nil)
  }
  
  func isLatestDocumentSchema() -> Bool {
    return userData.count <= 9
  }
  
  func getGender() -> String {
    let genderChar = isLatestDocumentSchema() ? userData[3] : userData[7]
    return genderChar == "M" ? "Masculino" : "Femenino"
  }
  
  func selectAvatar() -> UIImage {
    
    var name = "avatar_"
    
    name += getGender() == "Masculino" ? "male_" : "female_"
    
    name += String(Int(arc4random_uniform(UInt32(4 - 1))) + 1)
    /*
    if let image = NSDataAsset(name: name) {
      
    }*/
    return UIImage(named: name)!
    
    //return UIImage(named: "avatar")!
  }
}

