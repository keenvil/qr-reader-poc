//
//  ViewController.swift
//  MyWebRTCSwift
//
//  Created by Keiichi Unno on 6/22/15.
//  Copyright (c) 2015 Keiichi Unno. All rights reserved.
//

import AVFoundation
import UIKit
import SocketIOClientSwift

protocol WebRTCServiceDelegate {
    func getVideoFrame() -> CGRect
}

class WebRTCService: NSObject, RTCSessionDescriptionDelegate, RTCPeerConnectionDelegate {
    
    var delegate: WebRTCServiceDelegate? = nil
    
    let LOCAL_STREAM_ID = "LOCAL_STREAM"
    let AUDIO_TRACK_ID = "AUDIO_TRACK"
    let VIDEO_TRACK_ID = "VIDEO_TRACK"

    //UI
    var mediaStream: RTCMediaStream!
    
    var localVideoTrack: RTCVideoTrack!
    var localAudioTrack: RTCAudioTrack!
    
    var remoteVideoTrack: RTCVideoTrack!
    var remoteAudioTrack: RTCAudioTrack!
    
    var localView : RTCEAGLVideoView?
    var remoteView : RTCEAGLVideoView?
    
    // webrtc
    var peerConnectionFactory: RTCPeerConnectionFactory! = nil
    var peerConnection: RTCPeerConnection! = nil
    
    struct MediaConstraints {
        static let CategoryConstraints = RTCMediaConstraints(
            mandatoryConstraints: [
                RTCPair(key: "OfferToReceiveVideo", value: "true"),
                RTCPair(key: "OfferToReceiveAudio", value: "true")
            ],
            optionalConstraints: nil
        )
        
        static let VideoMediaConstraints = RTCMediaConstraints(
            mandatoryConstraints: [
                RTCPair(key: "maxWidth", value: "352"),
                RTCPair(key: "maxHeight", value: "288"),
                RTCPair(key: "maxFrameRate", value: "30")
            ],
            optionalConstraints: nil
        )
        
    }
    
    //State management
    var peerStarted: Bool = false
    var channelReady: Bool = false
    
    //Socket client
    var socket: SocketIOClient! = nil

    init(delegate : WebRTCServiceDelegate, localView: RTCEAGLVideoView, remoteView: RTCEAGLVideoView) {
        super.init()
        self.delegate = delegate
        self.localView = localView
        self.remoteView = remoteView
        initWebRTC();
        connectToSignalingServer();
        getMedia()
    }
    
    deinit {
        closeSession()
    }
    
    func signalingServerURL() -> NSURL? {
        return NSURL(string: "https://signaling-eabait.rhcloud.com")
    }
    
    func initWebRTC() {
        RTCPeerConnectionFactory.initializeSSL()
        peerConnectionFactory = RTCPeerConnectionFactory()
    }
    
    func getMedia() {
        mediaStream = peerConnectionFactory.mediaStreamWithLabel(LOCAL_STREAM_ID)
        
        // get the microphone
        localAudioTrack = peerConnectionFactory.audioTrackWithID(AUDIO_TRACK_ID)
        mediaStream.addAudioTrack(localAudioTrack)
        
        // get the front-facing camera
        var device : AVCaptureDevice? = nil
        for captureDevice in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
            let capDev = captureDevice as! AVCaptureDevice
            if capDev.position == .Front {
                device = capDev
                break
            }
        }
        
        var error : NSError? = nil
        do {
            try device?.lockForConfiguration()
        } catch let error1 as NSError {
            error = error1
            print(error)
        }
        
        let targetFrameRate : Float64 = 5
        
        for range in device!.activeFormat.videoSupportedFrameRateRanges {
            if range.minFrameRate <= targetFrameRate && range.maxFrameRate >= targetFrameRate {
                device?.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(targetFrameRate), flags: .Valid, epoch: 0)
                device?.activeVideoMinFrameDuration = CMTime(value: 1, timescale: Int32(targetFrameRate), flags: .Valid, epoch: 0)
                print("set framerate to \(targetFrameRate)")
            }
        }
        
        device?.unlockForConfiguration()
        
        // create video track using camera and add to media stream
        if let dev = device {
            let capturer = RTCVideoCapturer(deviceName: dev.localizedName)
            let vidSource = peerConnectionFactory.videoSourceWithCapturer(capturer, constraints: MediaConstraints.VideoMediaConstraints)
            let vidTrack = peerConnectionFactory.videoTrackWithID(VIDEO_TRACK_ID, source: vidSource)
            let audTrack = peerConnectionFactory.audioTrackWithID(AUDIO_TRACK_ID)
            
            vidTrack?.addRenderer(localView)
            
            mediaStream?.addVideoTrack(vidTrack)
            mediaStream?.addAudioTrack(audTrack)
            localView?.layer.borderWidth = 1
            localView?.layer.borderColor = UIColor.grayColor().CGColor
        }
    }
    
    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch _ {
        }
        do {
            try session.overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker)
        } catch _ {
        }
        do {
            try session.setActive(true)
        } catch _ {
        }
    }
    
    func stopPeerConnection() {
        if (peerConnection != nil) {
            peerConnection.close()
            peerConnection = nil
            peerStarted = false
        }
        
        if let videoTrack = mediaStream?.videoTracks.first {
            mediaStream?.removeVideoTrack(videoTrack as! RTCVideoTrack)
        }
        
        RTCPeerConnectionFactory.deinitializeSSL()
    }


    func hungUp() {
        let message : [String: AnyObject] = [
            "type" : "hangup"
        ]
        emmitSignalingMessage(message);
        stopPeerConnection()
    }
    
    func closeSession() {
        stopPeerConnection()
        socket.disconnect()
    }
    
    func makeCall() {
        if (!self.peerStarted) {
            self.peerConnection = self.prepareNewConnection();
        }
        self.peerConnection.createOfferWithDelegate(self, constraints: MediaConstraints.CategoryConstraints)
        self.peerStarted = true
    }

    func prepareNewConnection() -> RTCPeerConnection {
        var icsServers: [RTCICEServer] = []
        let rtcConfig: RTCConfiguration = RTCConfiguration()
        rtcConfig.tcpCandidatePolicy = RTCTcpCandidatePolicy.Disabled
        rtcConfig.bundlePolicy = RTCBundlePolicy.MaxBundle
        rtcConfig.rtcpMuxPolicy = RTCRtcpMuxPolicy.Require
        
        icsServers.append(RTCICEServer(URI: NSURL(string:"stun:stun.l.google.com:19302"), username: "", password: ""))
        icsServers.append(RTCICEServer(URI: NSURL(string:"stun:stun01.sipphone.com"), username: "", password: ""))
        icsServers.append(RTCICEServer(URI: NSURL(string:"turn:162.222.183.171:3478?transport=udp"), username: "1443005138:iapprtc", password: "wLA9l9Deg1ufKC/vd81kYEyOfDI="))

        peerConnection = peerConnectionFactory.peerConnectionWithICEServers(icsServers, constraints: nil, delegate: self)
        
        peerConnection.addStream(mediaStream);
        return peerConnection;
    }

    // RTCPeerConnectionDelegate - begin [
    func peerConnection(peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState) {
    }

    func peerConnection(peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState) {
    }

    func peerConnection(peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
    }

    func peerConnection(peerConnection: RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!) {
        if (candidate != nil) {
            let json:[String: AnyObject] = [
                "type" : "candidate",
                "sdpMLineIndex" : candidate.sdpMLineIndex,
                "sdpMid" : candidate.sdpMid,
                "candidate" : candidate.sdp
            ]
            emmitSignalingMessage(json)
        }
    }

    func peerConnection(peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            guard let videoTrack = stream.videoTracks.last as? RTCVideoTrack,
                let audTrack = stream.audioTracks.last as? RTCAudioTrack
            else { return }
            
            self.remoteVideoTrack = videoTrack
            self.remoteVideoTrack?.addRenderer(self.remoteView)
            
            self.remoteAudioTrack = audTrack
            self.configureAudioSession()
            
        })
    }

    func peerConnection(peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
        remoteVideoTrack = nil
    }

    func peerConnection(peerConnection: RTCPeerConnection!, didOpenDataChannel dataChannel: RTCDataChannel!) {
    }

    func peerConnectionOnRenegotiationNeeded(peerConnection: RTCPeerConnection!) {
    }
    //MARK [ RTCPeerConnectionDelegate - end ]

    //MARK [RTCSessionDescriptionDelegate - begin]
    func peerConnection(peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: NSError!) {
        if (error == nil) {
            peerConnection.setLocalDescriptionWithDelegate(self, sessionDescription: sdp)
            let json:[String: AnyObject] = [
                "type" : sdp.type,
                "sdp"  : sdp.description
            ]
            emmitSignalingMessage(json);
        }
    }

    func peerConnection(peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: NSError!) {
    }
    //MARK [RTCSessionDescriptionDelegate - end]
    
    func emmitSignalingMessage(msg:NSDictionary) {
        socket.emit("message", msg)
    }
    
    func connectToSignalingServer() {
        
        let nsServerURL = self.signalingServerURL()
        socket = SocketIOClient(socketURL: nsServerURL!, options: [])
        
        socket.on("connect") { data in
            self.channelReady = true
        }
        
        socket.on("disconnect") { data in
            self.channelReady = false
            self.closeSession()
        }
        
        socket.on("message") { (data, emitter) in
            if (data.count == 0) {
                return
            }

            let json = data[0] as! NSDictionary
            let type = json["type"] as! String

            if (type == "offer") {
                
                let sdp = RTCSessionDescription(type: type, sdp: json["sdp"] as! String)
                self.peerConnection = self.prepareNewConnection()
                self.peerConnection.setRemoteDescriptionWithDelegate(self, sessionDescription: sdp)
                self.peerConnection.createAnswerWithDelegate(self, constraints: MediaConstraints.CategoryConstraints)
                self.peerStarted = true;
                
            } else if (type == "answer" && self.peerStarted) {
                
                let sdp = RTCSessionDescription(type: type, sdp: json["sdp"] as! String)
                if (self.peerConnection == nil) {
                    return
                }
                self.peerConnection.setRemoteDescriptionWithDelegate(self, sessionDescription: sdp)
                
            } else if (type == "candidate" && self.peerStarted) {
                
                let candidate = RTCICECandidate(
                    mid: json["sdpMid"] as! String,
                    index: json["sdpMLineIndex"] as! Int,
                    sdp: json["candidate"] as! String)
                
                self.peerConnection.addICECandidate(candidate)
            
            } else if (type == "hangup" && self.peerStarted) {
        
                self.stopPeerConnection()
                
            } else {
                //Wrong message format. Close session
                self.channelReady = false
                self.closeSession()
            }
        }
        socket.connect();
    }
}
