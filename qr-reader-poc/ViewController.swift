//
//  ViewController.swift
//  qr-reader-poc
//
//  Created by Esteban Abait on 5/5/16.
//  Copyright © 2016 my-community. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  
  @IBOutlet weak var messageLabel:UILabel!
  
  var captureSession:AVCaptureSession?
  var videoPreviewLayer:AVCaptureVideoPreviewLayer?
  var qrCodeFrameView:UIView?
  
  var audioPlayer:AVAudioPlayer!
  
  // Added to support different barcodes
  let supportedBarCodes = [AVMetadataObjectTypePDF417Code]
  
  var userData: [String] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
      try AVAudioSession.sharedInstance().setActive(true)
      let url = Bundle.main.url(forResource: "beep", withExtension: "mp3")!
      audioPlayer = try AVAudioPlayer(contentsOf: url)
      if let player = audioPlayer {
        player.prepareToPlay()
      } else {
        print("Unable to load beep.mp3")
      }
    } catch {
      print("beep.mp3 couldnt be loaded")
    }
    
    // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
    // as the media type parameter.
    let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    
    messageLabel.text = "Detectando DNI"
    
    do {
      // Get an instance of the AVCaptureDeviceInput class using the previous device object.
      let input = try AVCaptureDeviceInput(device: captureDevice)
      
      // Initialize the captureSession object.
      captureSession = AVCaptureSession()
      // Set the input device on the capture session.
      captureSession?.addInput(input)
      
      // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
      let captureMetadataOutput = AVCaptureMetadataOutput()
      captureSession?.addOutput(captureMetadataOutput)
      
      // Set delegate and use the default dispatch queue to execute the call back
      captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      
      // Detect all the supported bar code
      captureMetadataOutput.metadataObjectTypes = supportedBarCodes
      
      // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
      videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
      videoPreviewLayer?.frame = view.layer.bounds
      view.layer.addSublayer(videoPreviewLayer!)
      
      // Start video capture
      captureSession?.startRunning()
      
      // Move the message label to the top view
      view.bringSubview(toFront: messageLabel)
      
      // Initialize QR Code Frame to highlight the QR code
      qrCodeFrameView = UIView()
      
      if let qrCodeFrameView = qrCodeFrameView {
        qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
        qrCodeFrameView.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView)
        view.bringSubview(toFront: qrCodeFrameView)
      }
      
    } catch {
      print(error)
      messageLabel.text = "Hubo un problema"
      return
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(true)

  }
  
  func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if metadataObjects == nil || metadataObjects.count == 0 {
      qrCodeFrameView?.frame = CGRect.zero
      messageLabel.text = "DNI no reconocido"
      return
    }
    
    // Get the metadata object.
    let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
    
    // Here we use filter method to check if the type of metadataObj is supported
    // Instead of hardcoding the AVMetadataObjectTypeQRCode, we check if the type
    // can be found in the array of supported bar codes.
    if supportedBarCodes.contains(metadataObj.type) {
      // if metadataObj.type == AVMetadataObjectTypeQRCode {
      // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
      let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
      qrCodeFrameView?.frame = barCodeObject!.bounds
      
      if metadataObj.stringValue != nil {
        showUser(metadataObj.stringValue)
      }
    }
  }
  
  func stopVideoCapturing() {
    self.captureSession?.stopRunning()
    self.videoPreviewLayer?.removeFromSuperlayer()
    self.videoPreviewLayer = nil;
    self.captureSession = nil;
  }
  
  func showUser(_ encodedUserData: String!) {
    self.userData = self.extractUserData(encodedUserData)
    //print(encodedUserData)
    if (userData.count >= 7) {
      let result = audioPlayer.play()
      print("Play file: \(audioPlayer.data) result \(result)")
      
      messageLabel.text = "DNI reconocido: " + userData[1]
      stopVideoCapturing()
      
      self.performSegue(withIdentifier: "second", sender: self)
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
    let navigationController = segue.destination as! UINavigationController
    
    let userDetailController = navigationController.topViewController as! SecondViewController
    userDetailController.userData = userData
  }
  
  func extractUserData(_ encodedUserData: String) -> [String] {
    return encodedUserData.characters.split{$0 == "@"}.map(String.init)
  }

}

