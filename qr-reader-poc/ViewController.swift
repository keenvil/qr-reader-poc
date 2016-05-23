//
//  ViewController.swift
//  qr-reader-poc
//
//  Created by Esteban Abait on 5/5/16.
//  Copyright © 2016 my-community. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  
  @IBOutlet weak var messageLabel:UILabel!
  
  var captureSession:AVCaptureSession?
  var videoPreviewLayer:AVCaptureVideoPreviewLayer?
  var qrCodeFrameView:UIView?
  
  // Added to support different barcodes
  let supportedBarCodes = [AVMetadataObjectTypePDF417Code]
  
  var userData: [String] = []
  
  
  override func viewWillAppear(animated: Bool) {
    // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
    // as the media type parameter.
    let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    
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
      captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
      
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
      view.bringSubviewToFront(messageLabel)
      
      // Initialize QR Code Frame to highlight the QR code
      qrCodeFrameView = UIView()
      
      if let qrCodeFrameView = qrCodeFrameView {
        qrCodeFrameView.layer.borderColor = UIColor.greenColor().CGColor
        qrCodeFrameView.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView)
        view.bringSubviewToFront(qrCodeFrameView)
      }
      
    } catch {
      print(error)
      messageLabel.text = "Unrecognized QR code"
      return
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(true)

  }
  
  func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if metadataObjects == nil || metadataObjects.count == 0 {
      qrCodeFrameView?.frame = CGRectZero
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
      let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj)
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
  
  func showUser(encodedUserData: String!) {
    userData = extractUserData(encodedUserData)
    
    if (userData.count >= 9) {
      messageLabel.text = "DNI reconocido: " + userData[1]
      stopVideoCapturing()
      performSegueWithIdentifier("second", sender: self)
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
    let navigationController = segue.destinationViewController as! UINavigationController
    
    let userDetailController = navigationController.topViewController as! SecondViewController
    userDetailController.userData = userData
  }
  
  func extractUserData(encodedUserData: String) -> [String] {
    return encodedUserData.characters.split{$0 == "@"}.map(String.init)
  }

}

