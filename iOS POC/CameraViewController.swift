//
//  ViewController.swift
//  Guided Camera
//
//  Created by zawyenaing on 2018/10/01.
//  Copyright © 2018 swift.test. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation
import WebKit

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
        
    
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var cameraActionView: UIView!
    @IBOutlet weak var lbAgeValue: UILabel!
    @IBOutlet weak var lbGenderValue: UILabel!
    
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCaptureVideoDataOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var base46String: String? = nil
    
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]
        
        // 1
        let contentController = WKUserContentController()
        contentController.add(self, name: "camera")
        contentController.add(self, name: "data")
        
        // 2
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        // 3
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height), configuration: config)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isHidden = true
        self.view.addSubview(webView)
        
        webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0).isActive = true
        webView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
        
        
        // 4
        //https://demo.morphcast.com/native-app-webview/ios-index_exec.html
        if let url = URL(string: "https://demo.morphcast.com/native-app-webview/ios-index_exec.html") {
            webView.load(URLRequest(url: url))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        do {
            	
            let camera = self.cameraWithPosition(position: .front)
            
            let input = try AVCaptureDeviceInput(device: camera!)
            stillImageOutput = AVCaptureVideoDataOutput()
            let bufferQueue = DispatchQueue(label: "bufferRate", qos: .userInteractive, attributes: .concurrent)
            stillImageOutput.setSampleBufferDelegate(self, queue: bufferQueue)
                
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupCameraPreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    func setupCameraPreview() {
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.previewView.bounds
            }
        }
    }
    
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        
        for device in discoverySession.devices {
            if device.position == position {
                return device
            }
        }

        return nil
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciimage : CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let image : UIImage = self.convert(cmage: ciimage)
        let img = image.rotate(radians: .pi/2)
        let resizeImage = self.resizeImage(image: img, newHeight: 320)
        self.base46String = resizeImage?.toBase64()
        
        /*let dataDecoded : Data = Data(base64Encoded: self.base46String ?? "", options: .ignoreUnknownCharacters)!
        let decodedimage = UIImage(data: dataDecoded)
        print(decodedimage)*/
        
    }
    // Convert CIImage to CGImage
    func convert(cmage:CIImage) -> UIImage {
         let context:CIContext = CIContext.init(options: nil)
         let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
         let image:UIImage = UIImage.init(cgImage: cgImage)
         return image
    }
    func resizeImage(image: UIImage, newHeight: CGFloat) -> UIImage? {

        let scale = newHeight / image.size.height
        let newWidth = image.size.width * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
extension UIImage {
    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0,
                                 y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -origin.y, y: -origin.x,
                            width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return rotatedImage ?? self
        }

        return self
    }
    func toBase64() -> String? {
        guard let imageData = UIImageJPEGRepresentation(self, 0.5) else { return nil }
           return imageData.base64EncodedString()
       }
}

extension CameraViewController:WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "camera", let dict = message.body as? NSDictionary {
            if let maxSize = dict["value"] as? Int {
                onCameraFrame(maxSize: maxSize)
            }
        }
    
        if message.name == "data", let dict = message.body as? NSDictionary {
            if let type = dict["type"] as? String, let value = dict["value"] as? String {
                onData(type: type, value: value)
            }
        }
    }
    
    // JS Callbacks
    private func onCameraFrame(maxSize: Int) {
        /*
         App developer shall implement the following behaviour:
         
         1) Retrieve a frame from camera
         
         * We suggest to resize frames before passing them to the WebView and to encode them in base64 format
         * Strings are processed faster than binary data through the JavaScript Interface
         
         2) resize it to maxSize x maxSize (maintaining the aspect ratio)
         3) Convert the frame to Base64
         4) return the Base64 String data:image/jpeg;base64,
         */
        let base64Image = (self.base46String != nil) ? "data:image/jpeg;base64," + self.base46String! : ""
        
        webView.evaluateJavaScript("resolveFrame('\(base64Image)')", completionHandler: nil)
    }
    
    private func onData(type: String, value: String) {
        /*
         type: String
         ["AGE","GENDER","EMOTION","FEATURES","POSE","AROUSAL_VALENCE","ATTENTION"]
         value: Json-stringified of the result
         
         App developer can use the values returned from the webview to implement the desired behavior (e.g update the App view, send data to a custom db ...)
         */
        
        print(type + " " + value);
        if type != "" && value != "" {
            let data = value.data(using: .utf8)!
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:AnyObject]
                {
                   
                    print("got json")
                    switch type {
                    case "AGE":
                        let age = jsonObject["numericAge"] as! Int
                        self.lbAgeValue.text = String(age)
                    case "GENDER":
                        let genderObject = jsonObject["gender"] as! [String:AnyObject]
                        let maleValue = genderObject["Male"] as! Double
                        let feMaleValue = genderObject["Female"] as! Double
                        let genderValue = maleValue > feMaleValue ? "Male" : "Female"
                        self.lbGenderValue.text = genderValue
                    default:
                        return
                    }
                } else {
                    print("bad json")
                }
            } catch let error as NSError {
                print(error)
            }
        }
    }
}
