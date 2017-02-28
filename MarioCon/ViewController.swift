//
//  ViewController.swift
//  MarioCon
//
//  Created by Jacky on 27/2/17.
//  Copyright © 2017 Jacky. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate {

    @IBOutlet weak var joypadBase: UIImageView!
    @IBOutlet weak var joypadHead: UIImageView!
    @IBOutlet weak var btnAction: UIButton!
    @IBOutlet weak var statusLbl: UILabel!
    
    //Multipeer Connectivity
    let kServiceType = "multi-peer-chat"
    var myPeerID:MCPeerID!
    var session:MCSession!
    var browser:MCBrowserViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //UIGestureRecognizer
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handlePan(_:)))
        self.joypadHead.addGestureRecognizer(panGesture)
        
        //Multipeer Connectivity
        
        //session
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
        self.browser = MCBrowserViewController(serviceType: kServiceType, session: self.session)
        self.browser.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.landscape
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    //MARK: - MCNearbyServiceBrowserDelegate
    
    func browserViewController(_ browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
        
        print("peerID: \(peerID)")
        
        return true
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        
        print("browser finished")
        
        self.browser.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        
        print("browser cancelled")
        
        self.browser.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - MCSessionDelegate
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        
        return certificateHandler(true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        print("myPeerID: \(self.session.myPeerID)")
        print("connectd peerID: \(peerID)")
        
        switch state {
            
        case .connecting:
            print("Connecting..")
            break
            
        case .connected:
            print("Connected..")
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                self.statusLbl.text = "Connected !"
            })
            
            break
            
        case .notConnected:
            print("Not Connected..")
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                self.statusLbl.text = "Not Connected"
            })
            
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        print("hand didReceiveData")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
        print("hand didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
        print("hand didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
        print("hand didReceiveStream")
    }
    
    //MARK:- Util
    
    func calcDistanceWithOrigin(_ origin:CGPoint, andDestination destination:CGPoint) -> CGFloat {
        
        let deltaX = destination.x - origin.x
        let deltaY = destination.y - origin.y
        
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
    
    //MARK:- IBActions
    
    @IBAction func browseTapped(_ sender: AnyObject) {
        
        self.present(self.browser, animated: true, completion: nil)
    }
    
    @IBAction func actionTapped(_ sender: AnyObject) {
        
        let dict = ["action":"jump"]
        let dictData = NSKeyedArchiver.archivedData(withRootObject: dict)
        
        do {
            try self.session.send(dictData, toPeers: self.session.connectedPeers, with: .reliable)
        } catch {
            print("error sending data")
        }
    }
    
    //MARK:- UIGestureRecognizers
    
    var touchDelta = CGPoint.zero
    var prevTouchPoint = CGPoint.zero
    var MAX_RADIUS:CGFloat = 84.0
    var isTouchWithinBound = true
    
    func handlePan(_ recognizer:UIPanGestureRecognizer) {
        
        let touchPoint = recognizer.location(in: self.view)
        
        if(recognizer.view == self.joypadHead) {
            
            if(recognizer.state == .began) {
                
                touchDelta = CGPoint(
                    x: touchPoint.x - self.joypadBase.center.x,
                    y: touchPoint.y - self.joypadBase.center.y)
                
                prevTouchPoint = touchPoint
            }
            else if(recognizer.state == .changed) {
               
                //make sure that current touch point is still on top of the joypad head
                
                if self.joypadHead.frame.contains(touchPoint) {
                
                    isTouchWithinBound = true
                    let touchToPreviousDeltaX = touchPoint.x - prevTouchPoint.x
                    
                    //Send movement delta
                    if self.session.connectedPeers.count >= 1 {
                        
                        let dict = [
                            "action":"move",
                            "movementDelta":NSNumber(value: Float(touchToPreviousDeltaX))] as [String : Any]
                        let dictData = NSKeyedArchiver.archivedData(withRootObject: dict)
                        
                        do {
                            try self.session.send(dictData, toPeers: self.session.connectedPeers, with: .reliable)
                        } catch {
                            print("error sending data")
                        }
                    }
                    
                    // replace previous touch point with the current touch point
                    prevTouchPoint = touchPoint
                    
                    let dx = self.joypadBase.center.x - touchPoint.x
                    let dy = self.joypadBase.center.y - touchPoint.y
                    
                    let touchDistance = self.calcDistanceWithOrigin(self.joypadBase.center, andDestination: touchPoint)
                    let touchAngle = Float(atan2(dy, dx))
                    
                    if(touchDistance > MAX_RADIUS)
                    {
                        //if out of bounds (if out of the base's perimeter, keep it on the perimeter, using the equation of a circle)
                        self.joypadHead.center = CGPoint(
                            x: self.joypadBase.center.x - CGFloat(cosf(touchAngle)) * MAX_RADIUS,
                            y: self.joypadBase.center.y - CGFloat(sinf(touchAngle)) * MAX_RADIUS)
                    }
                    else
                    {
                        self.joypadHead.center = CGPoint(
                            x: touchPoint.x - touchDelta.x,
                            y: touchPoint.y - touchDelta.y)
                    }
                }
                else {
                    
                    isTouchWithinBound = false
                }
            }
            else if(recognizer.state == .ended || !isTouchWithinBound) {
                
                let dict = ["action":"release"]
                let dictData = NSKeyedArchiver.archivedData(withRootObject: dict)
                
                do {
                    try self.session.send(dictData, toPeers: self.session.connectedPeers, with: .reliable)
                } catch {
                    print("error sending data")
                }
                
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    
                    recognizer.view?.center = self.joypadBase.center
                })
            }
        }
    }
}

