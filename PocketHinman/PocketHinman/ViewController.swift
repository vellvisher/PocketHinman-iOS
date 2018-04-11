//
//  ViewController.swift
//  PocketHinman
//
//  Created by Ross Harding on 4/3/18.
//  Copyright © 2018 Harding LLC. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    // MARK: Outlets
    
    @IBOutlet var sliderView: UIView!
    @IBOutlet var slider: UISlider!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var cameraView: UIView!
    @IBOutlet var cameraBar: UIView!
    
    @IBOutlet var photosButton: UIButton!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    
    @IBOutlet var calloutView: CalloutView!
    @IBOutlet var calloutArrow: UIImageView!
    
    
    // MARK: Properties
    
    let captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    let photoOutput = AVCapturePhotoOutput()
    var videoDeviceInput: AVCaptureDeviceInput!
    
    var imageView = UIImageView()
    var newMedia: Bool = false
    
    var alpha: Double = 0.5 {
        didSet {
            calloutView.alphaLabel.text = "\(Double(round(alpha*10)/10))"
            updateImageAlpha()
        }
    }
    
    var sliderValue: Float = 0.5 {
        didSet {
            
        }
    }
    
    var isPlaying: Bool = false {
        didSet {
            if isPlaying {
                playPauseButton.setImage(#imageLiteral(resourceName: "Pause-Button-Sized"), for: .normal)
                alpha = 1
                flicker()
            } else {
                playPauseButton.setImage(#imageLiteral(resourceName: "Play-Button-Sized"), for: .normal)
                cameraView.isHidden = false
                imageView.isHidden = false
                configureAlphaLabel()
            }
        }
    }
    
    
    // MARK: Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        isPlaying = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        calloutView.isHidden = true
        calloutArrow.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        beginCapture()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    // MARK: UI Configuration
    
    func configureView() {
        UIApplication.shared.isStatusBarHidden = true
        self.navigationController?.isNavigationBarHidden = true
        configureCameraButtonAnimation()
        configureCallout()
        configureImageView()
        configureSlider()
    }
    
    func configureSlider() {
        
        slider.maximumValue = 1
        slider.minimumValue = 0.05
        
        if let sliderVal = UserDefaults.standard.value(forKey: "sliderValue") as! Float? {
            sliderValue = sliderVal
        }
        slider.value = sliderValue
    }
    
    func configureCallout() {
        configureStepper()
        configureAlphaLabel()
        calloutView.imageView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
        calloutView.contentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
        calloutView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
        calloutView.panResizeButton.addTarget(self, action: #selector(performResizeImageSegue), for: .touchUpInside)
    }
    
    func configureStepper() {
        calloutView.stepper.addTarget(self, action: #selector(changeStepper(_:)), for: .touchUpInside)
        calloutView.panResizeButton.addTarget(self, action: #selector(panResizeImage), for: .touchUpInside)
        calloutView.stepper.maximumValue = 1
        calloutView.stepper.minimumValue = 0
        calloutView.stepper.stepValue = 0.1
    }
    
    func configureAlphaLabel() {
        if let alphaValue = UserDefaults.standard.value(forKey: "alpha") as! Double? {
            alpha = alphaValue
        } else {
            alpha = 0.5
        }
        calloutView.stepper.value = alpha
    }
    
    func configureImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = CGFloat(alpha)
        view.insertSubview(imageView, aboveSubview: cameraView)
    }
    
    func configureCameraButtonAnimation() {
        photosButton.setImage(#imageLiteral(resourceName: "Photos-Highlighted"), for: .highlighted)
        settingsButton.setImage(#imageLiteral(resourceName: "Settings-Highlighted"), for: .highlighted)
        cameraButton.setImage(#imageLiteral(resourceName: "Camera-Highlighted"), for: .highlighted)
        cancelButton.setImage(#imageLiteral(resourceName: "X-Highlighted"), for: .highlighted)
    }
    
    
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ResizeImageSegue" {
            let destinationVC = segue.destination as! ResizeImageViewController
            destinationVC.image = imageView.image
        }
    }
    
    
    // MARK:  UI Events
    
    @IBAction func togglePlayPause(_ sender: UIButton) {
        isPlaying = !isPlaying
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        sliderValue = sender.value
    }
    
    @IBAction func changeStepper(_ sender: UIStepper) {
        alpha = sender.value
        UserDefaults.standard.set(alpha, forKey: "alpha")
    }
    
    func updateImageAlpha() {
        imageView.alpha = CGFloat(alpha)
    }
    
    @objc func panResizeImage() {
        
    }
    
    @IBAction func photosTapped(_ sender: UIButton) {
        useImageLibrary()
    }
    
    @IBAction func settingsTapped(_ sender: UIButton) {
        if calloutView.isHidden {
            calloutView.isHidden = false
            calloutArrow.isHidden = false
            view.bringSubview(toFront: calloutView)
            view.bringSubview(toFront: calloutArrow)
        } else {
            calloutView.isHidden = true
            calloutArrow.isHidden = true
        }
        
    }
    
    @IBAction func cameraTapped(_ sender: UIButton) {
        takePhoto()
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        imageView.image = nil
    }
    
    
    
    // Convenience Functions
    
    func presentErrorAlert() {
        let alert = UIAlertController(title: "Error", message: "An error occurred. Please try again later.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }
    
    @objc func performResizeImageSegue() {
        if imageView.image != nil {
            self.performSegue(withIdentifier: "ResizeImageSegue", sender: nil)
        }
    }
    
    
    // MARK: Flickering
    
    func flicker() {
        if self.isPlaying {
            if self.sliderValue != 1 {
                self.cameraView.isHidden = self.imageView.isHidden
                self.imageView.isHidden = !self.imageView.isHidden
            } else {
                self.cameraView.isHidden = true
                self.imageView.isHidden = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(sliderValue)) {
                self.flicker()
            }
        }
    }
    
    
    // MARK: Camera and library image selection
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        self.dismiss(animated: true, completion: nil)
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            
            imageView.image = image
            imageView.frame = CGRect(x: 0, y: sliderView.frame.maxY, width: view.frame.width, height: cameraBar.frame.minY - sliderView.frame.maxY)
            
            if (newMedia == true) {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(ViewController.image(image:didFinishSavingWithError:contextInfo:)), nil)
            }
            
        }
    }
    
    @objc func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo:UnsafeRawPointer) {
        
        if error != nil {
            let alert = UIAlertController(title: "Save Failed", message: "Failed to save image", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func takePhoto() {
        
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isHighResolutionPhotoEnabled = true
        if self.videoDeviceInput.device.isFlashAvailable {
            photoSettings.flashMode = .auto
        }
        
        if let firstAvailablePreviewPhotoPixelFormatTypes = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: firstAvailablePreviewPhotoPixelFormatTypes]
        }
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func useImageLibrary() {
        
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.savedPhotosAlbum) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true,
                         completion: nil)
            newMedia = false
        }
    }
    
    
    // MARK: Capture Session
    
    func beginCapture() {
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        do {
            
            var captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            
            let dualCameraDeviceType: AVCaptureDevice.DeviceType
            if #available(iOS 11, *) {
                dualCameraDeviceType = .builtInDualCamera
            } else {
                dualCameraDeviceType = .builtInDuoCamera
            }
            
            if let dualCameraDevice = AVCaptureDevice.default(dualCameraDeviceType, for: AVMediaType.video, position: .back) {
                captureDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
                captureDevice = backCameraDevice
            } else {
                presentErrorAlert()
                return
            }
            
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: captureDevice!)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
            } else {
                captureSession.commitConfiguration()
                return
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                
                photoOutput.isHighResolutionCaptureEnabled = true
                photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            } else {
                captureSession.commitConfiguration()
                return
            }
            
            captureSession.commitConfiguration()
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = cameraView.layer.bounds
            
            cameraView.layer.addSublayer(videoPreviewLayer!)
            
            captureSession.startRunning()
            
            
        } catch {
            presentErrorAlert()
        }
    }
    
    func endCapture() {
        captureSession.stopRunning()
    }

}



extension ViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
                
                if let image = UIImage(data: dataImage) {
                    self.imageView.frame = CGRect(x: 0, y: sliderView.frame.maxY, width: view.frame.width, height: cameraBar.frame.minY - sliderView.frame.maxY)
                    self.imageView.image = image
                }
            }
        }
        
    }
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let data = photo.fileDataRepresentation(),
            let image =  UIImage(data: data)  else {
                return
        }
        self.imageView.frame = CGRect(x: 0, y: sliderView.frame.maxY, width: view.frame.width, height: cameraBar.frame.minY - sliderView.frame.maxY)
        self.imageView.image = image
    }
    
}

