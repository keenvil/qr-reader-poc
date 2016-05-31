//
//  ViewController.swift
//  MyWebRTCSwift
//
//  Created by Esteban Abait on 5/26/16.
//

import UIKit
import Foundation

class VideoCallViewController : UIViewController, RTCEAGLVideoViewDelegate, WebRTCServiceDelegate {
    
    @IBOutlet weak var videoOutlet: UIView!
    var localView : RTCEAGLVideoView?
    var remoteView : RTCEAGLVideoView?
    var webRTCService : WebRTCService!
  var timer:NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addVideoViews()
        
        webRTCService = WebRTCService(delegate: self, localView: localView!, remoteView: remoteView!)
      
        timer = NSTimer.scheduledTimerWithTimeInterval(3, target:self, selector: #selector(VideoCallViewController.makeCall), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func addVideoViews() {
        remoteView = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        remoteView?.delegate = self
        videoOutlet.addSubview(remoteView!)
        
        localView = RTCEAGLVideoView(frame: CGRect(x: 10, y: 70, width: videoOutlet.frame.size.width / 4, height: videoOutlet.frame.size.width / 4 * 960 / 640))
        localView?.delegate = self
        videoOutlet.addSubview(localView!)
    }
  
    func connectionEstablished() {
      print("Got answer")
      self.timer?.invalidate()
    }
    
    func makeCall() {
      print("Sending conn offer")
      webRTCService.makeCall()
    }
  
  func connectionTerminated() {
    dismissViewControllerAnimated(true, completion: nil)
  }
    
    @IBAction func hungUp(sender: AnyObject) {
        webRTCService.hungUp()
    }
    
    func videoView(videoView: RTCEAGLVideoView!, didChangeVideoSize size: CGSize) {
        // just keep aspect ratio
        var viewSize : CGSize? = nil
        if self.localView == videoView {
            viewSize = CGSize(width: (self.localView?.frame)!.size.width , height: (self.localView?.frame)!.size.width * size.height / size.width)
            self.localView?.frame = CGRect(origin: (self.localView?.frame)!.origin, size: viewSize!)
        } else if self.remoteView == videoView {
            viewSize = CGSize(width: (self.remoteView?.frame)!.size.width , height: (self.remoteView?.frame)!.size.width * size.height / size.width)
            self.remoteView?.frame = CGRect(origin: (self.remoteView?.frame)!.origin, size: viewSize!)
            if (self.remoteView?.frame)!.size.height < self.view.frame.size.height {
                viewSize = CGSize(width: self.view.frame.size.height * size.width / size.height, height: self.view.frame.size.height)
                let x_orig = (self.remoteView?.frame)!.origin.x - viewSize!.width / 2  + self.view.frame.size.width / 2
                let y_orig = (self.remoteView?.frame)!.origin.y
                let newOrigin = CGPoint(x: x_orig, y: y_orig)
                self.remoteView?.frame = CGRect(origin: newOrigin, size:viewSize!)
            }
        }
    }
    
}
