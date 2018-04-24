import UIKit
import AVFoundation
import Vision
import Photos

let imageSize = 368

class ViewController: UIViewController {
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var previewView: UIImageView!
    @IBOutlet weak var messageLabel: UILabelStroked!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabelStroked!
    
    @IBOutlet weak var captureButton: UIButton!
    @IBAction func tappedCaptureButton(sender: UIButton) {
        shootVideo()
    }
    
    @IBOutlet weak var selectButton: UIButton!
    @IBAction func tappedSelectButton(sender: UIButton) {
        selectVideo()
    }
    
    let com = {
        Common(imageSize,imageSize)
    }()
    
    let modelCoreML = MobileOpenPose()
    let targetImageSize = CGSize(width: imageSize, height: imageSize) // must match model data input
    
    var captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    var cameraLayer: AVCaptureVideoPreviewLayer!
    
    let fileOutput = AVCaptureMovieFileOutput()
    var isRecording = false
    var selectedFileURL: URL?
    var editingImage: UIImage?
    var completedDetection: Bool = false
    
    var deviceType: UIUserInterfaceIdiom?
    var isIPhoneX: Bool = false
    
    var canUseCamera: Bool?
    var canUsePhotoLibrary: Bool?
    
    lazy var classificationRequest: [VNRequest] = {
        do {
            // Load the Custom Vision model.
            // To add a new model, drag it to the Xcode project browser making sure that the "Target Membership" is checked.
            // Then update the following line with the name of your new model.
            let model = try VNCoreMLModel(for: modelCoreML.model)
            let classificationRequest = VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
            return [ classificationRequest ]
        } catch {
            fatalError("Can't load Vision ML model: \(error)")
        }
    }()
    
    func handleClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else { fatalError() }
        let mlarray = observations[0].featureValue.multiArrayValue!
        
        DispatchQueue.global().async {
            let length = mlarray.count
            let doublePtr =  mlarray.dataPointer.bindMemory(to: Double.self, capacity: length)
            let doubleBuffer = UnsafeBufferPointer(start: doublePtr, count: length)
            let mm = Array(doubleBuffer)
        
            DispatchQueue.main.sync {
                self.drawLine(mm)
            }
        }
    }
    
    func drawLine(_ mm: Array<Double>) {
        let connections = com.estimatePose(mm)
        let CocoPairsRender = com.cocoPairs[0..<com.cocoPairs.count-2]
        
        UIGraphicsBeginImageContext(targetImageSize)
        var context:CGContext = UIGraphicsGetCurrentContext()!
        
        for human in connections.values {
            for (partIdx, part) in human.enumerated() {
                if (partIdx >= com.cocoColors.count){ continue }
                if !CocoPairsRender.contains(part.partIdx){ continue }
                
                let center1 = CGPoint(x: (CGFloat(part.c1.0) + 0.5) * 8,
                                      y: (CGFloat(part.c1.1) + 0.5) * 8)
                let center2 = CGPoint(x: (CGFloat(part.c2.0) + 0.5) * 8,
                                      y: (CGFloat(part.c2.1) + 0.5) * 8)
                
                guard let color = com.cocoColors[partIdx] else {continue}
                
                addLine(context: &context, fromPoint: center1, toPoint: center2, color: color)
            }
        }
        
        var boneImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        var mainImage: UIImage = editingImage!
        
        // Resize width to a multiple of 16.
        mainImage = com.resizeImage(image: mainImage, size: mainImage.size, useToMakeVideo: true)
        
        // Crop bone image.
        // Since the image for detection was resized while keeping the aspect ratio at self.uIImageToPixelBuffer,
        // it's necessary to remove padding.
        let boneImageCropped: UIImage = com.cropImage(image: boneImage, aspectX: mainImage.size.width, aspectY: mainImage.size.height)
        
        // Fit to the size of main image.
        boneImage = com.resizeImage(image: boneImageCropped, size: mainImage.size)
        
        // Superimpose the image and bones.
        editingImage = com.superimposeImages(mainImage: mainImage, subImage: boneImage)
        
        completedDetection = true
    }
    
    func addLine(context: inout CGContext, fromPoint start: CGPoint, toPoint end:CGPoint, color: UIColor) {
        context.setLineWidth(3.0)
        context.setStrokeColor(color.cgColor)
        
        context.move(to: start)
        context.addLine(to: end)
        
        context.closePath()
        context.strokePath()
    }
    
    func shootVideo() {
        if !self.isRecording {
            // Start recording.
            messageLabel.isHidden = true
            
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory = paths[0] as String
            let fileURL : NSURL = NSURL(fileURLWithPath: "\(documentsDirectory)/temp.mp4")
            fileOutput.startRecording(to: fileURL as URL, recordingDelegate: self)
            
            // Change the shape of capture button to square.
            captureButton.layer.cornerRadius = 0
            isRecording = true
        } else {
            // Stop Recording.
            fileOutput.stopRecording()
            
            // Change the shape of capture button to circle.
            captureButton.layer.cornerRadius = captureButton.bounds.width / 2
            isRecording = false
        }
    }
    
    func updateSelectButton() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        let last = fetchResult.lastObject
        
        if let lastAsset = last {
            // There are videos in photo library.
            let targetSize: CGSize = CGSize(width: 50, height: 50)
            let options: PHImageRequestOptions = PHImageRequestOptions()
            options.version = .current
            
            // Get the last video from photo library.
            PHImageManager.default().requestImage(
                for: lastAsset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options,
                resultHandler: { image, _ in
                    if self.canUsePhotoLibrary! {
                        DispatchQueue.main.async {
                            self.selectButton.setImage(image, for: .normal)
                            self.selectButton.isHidden = false
                        }
                    }
                }
            )
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deviceType = UIDevice.current.userInterfaceIdiom
        guard deviceType == .phone || deviceType == .pad else {
            fatalError("ERROR: Invalid device.")
        }
        
        let deviceName = com.getDeviceName()
        if deviceType == .phone && deviceName.range(of: "iPhone10") != nil {
            isIPhoneX = true
        }
        
        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 3.0)
        
        cameraLayer = AVCaptureVideoPreviewLayer(session: self.captureSession) as AVCaptureVideoPreviewLayer
        cameraLayer.frame = self.view.bounds
        cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraView.layer.addSublayer(cameraLayer)
        
        messageLabel.strokedText = "Shoot or select a video."
        
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.layer.borderWidth = 3
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                self.canUseCamera = true
                DispatchQueue.main.async {
                    self.captureButton.isHidden = false
                }
                self.setupCamera()
            } else {
                self.canUseCamera = false
            }
        }
        
        PHPhotoLibrary.requestAuthorization() { (status) -> Void in
            if status == .authorized {
                self.canUsePhotoLibrary = true
                self.updateSelectButton()
            } else {
                self.canUsePhotoLibrary = false
                DispatchQueue.main.async {
                    self.captureButton.isHidden = true
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let url: URL = selectedFileURL else {
            return
        }
        
        // Selected a video from photo library.
        if ["MOV", "MP4", "M4V"].index(of: url.pathExtension.uppercased()) != nil {
            detectBone(url)
        } else {
            showAlert(title: "", message: "You can select only mov, mp4 or m4v video.", btnText: "OK")
        }
        
        selectedFileURL = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraLayer.frame = self.view.bounds
        
        if isIPhoneX {
            // Place view at (0, 0).
            cameraView.frame = CGRect(x: 0, y: 0, width: cameraView.frame.width, height: cameraView.frame.height)
        }
    }
    
    func setupCamera() {
        let deviceDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
        
        if let device = deviceDiscovery.devices.last {
            captureDevice = device
            beginSession()
        }
    }
    
    func beginSession() {
        let videoInput = try? AVCaptureDeviceInput(device: videoDevice!) as AVCaptureDeviceInput
        
        captureSession.addInput(videoInput!)
        captureSession.addOutput(fileOutput)

        if deviceType == .phone {
            // iPhone
            captureSession.sessionPreset = .hd1920x1080
        } else {
            // iPad
            captureSession.sessionPreset = .vga640x480
        }
        
        captureSession.startRunning()
    }
    
    func detectBone(_ inputURL: URL) {
        let outputURL: URL = NSURL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("\(NSUUID().uuidString).mp4")!
        
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov) else {
            print("ERROR: Failed to construct AVAssetWriter.")
            return
        }
        
        let avAsset = AVURLAsset(url: inputURL, options: nil)
        let composition = AVVideoComposition(asset: avAsset, applyingCIFiltersWithHandler: { request in })
        let track = avAsset.tracks(withMediaType: AVMediaType.video)
        
        guard let media = track[0] as AVAssetTrack? else {
            print("ERROR: There is no video track.")
            return
        }
        
        DispatchQueue.main.async {
            self.messageLabel.isHidden = true
            self.captureButton.isHidden = true
            self.selectButton.isHidden = true
            self.progressLabel.strokedText = "Detecting bones...(0%)"
            self.progressLabel.isHidden = false
            self.progressView.setProgress(0.0, animated: false)
            self.progressView.isHidden = false
        }
        
        let naturalSize: CGSize = media.naturalSize
        let preferedTransform: CGAffineTransform = media.preferredTransform
        let size = naturalSize.applying(preferedTransform)
        let width = fabs(size.width)
        let height = fabs(size.height)
        
        let outputSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ] as [String: Any]
        
        let writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings as [String : AnyObject])
        videoWriter.add(writerInput)
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
            ]
        )
        
        writerInput.expectsMediaDataInRealTime = true
        
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: kCMTimeZero)
        
        let generator = AVAssetImageGenerator(asset: avAsset)
        
        // Settings to get captures of all frames.
        // Without these settings, you can only get captures of integral seconds.
        generator.requestedTimeToleranceAfter = kCMTimeZero
        generator.requestedTimeToleranceBefore = kCMTimeZero
        
        var buffer: CVPixelBuffer? = nil
        var frameCount = 0
        let durationForEachImage = 1
        
        let length: Double = Double(CMTimeGetSeconds(avAsset.duration))
        let fps: Int = Int(1 / CMTimeGetSeconds(composition.frameDuration))
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.cameraView.isHidden = true
            }
                
            for i in stride(from: 0, to: length, by: 1.0 / Double(fps)) {
                autoreleasepool {
                    // Capture an image from the video file.
                    let capturedImage : CGImage! = try? generator.copyCGImage(at: CMTime(seconds: i, preferredTimescale : 600), actualTime: nil)
                    
                    var orientation: UIImageOrientation
                    
                    // Rotate the captured image.
                    if preferedTransform.tx == naturalSize.width && preferedTransform.ty == naturalSize.height {
                        orientation = UIImageOrientation.down
                    } else if preferedTransform.tx == 0 && preferedTransform.ty == 0 {
                        orientation = UIImageOrientation.up
                    } else if preferedTransform.tx == 0 && preferedTransform.ty == naturalSize.width {
                        orientation = UIImageOrientation.left
                    } else {
                        orientation = UIImageOrientation.right
                    }
                    
                    let tmpImageToEdit = UIImage(cgImage: capturedImage, scale: 1.0, orientation: orientation)
                    
                    // Resize width to a multiple of 16.
                    self.editingImage = self.com.resizeImage(image: tmpImageToEdit, size: tmpImageToEdit.size, useToMakeVideo: true)
                    
                    let tmpImageToDetect: UIImage = UIImage(cgImage: capturedImage)
                    let bufferToDetect = self.uiImageToPixelBuffer(tmpImageToDetect, targetSize: self.targetImageSize, orientation: orientation)!
                    
                    do {
                        // Detect bones.
                        let classifierRequestHandler = VNImageRequestHandler(cvPixelBuffer: bufferToDetect, options: [:])
                        try classifierRequestHandler.perform(self.classificationRequest)
                    } catch {
                        print("Error: Failed to detect bones.")
                        print(error)
                    }
                    
                    // Repeat until the Detection is completed.
                    while true {
                        if self.completedDetection {
                            buffer = self.com.getPixelBufferFromCGImage(cgImage: self.editingImage!.cgImage!)
                            self.completedDetection = false
                            break
                        }
                    }
                    
                    let frameTime: CMTime = CMTimeMake(Int64(__int32_t(frameCount) * __int32_t(durationForEachImage)), __int32_t(fps))
                    
                    // Repeat until the adaptor is ready.
                    while true {
                        if (adaptor.assetWriterInput.isReadyForMoreMediaData) {
                            adaptor.append(buffer!, withPresentationTime: frameTime)
                            break
                        }
                    }
                    
                    frameCount += 1
                }
                
                let progressRate = floor(i / length * 100)
                
                DispatchQueue.main.async {
                    self.previewView.image = self.editingImage!
                    self.progressLabel.strokedText = "Detecting bones...(" + String(Int(progressRate)) + "%)"
                    self.progressView.setProgress(Float(progressRate / 100), animated: true)
                }
            }
            
            writerInput.markAsFinished()
            
            DispatchQueue.main.async {
                self.previewView.image = nil
                self.progressLabel.strokedText = "Detecting bones...(100%)"
                self.progressView.setProgress(1.0, animated: true)
                self.cameraView.isHidden = false
            }
            
            videoWriter.endSession(atSourceTime: CMTimeMake(Int64((__int32_t(frameCount)) *  __int32_t(durationForEachImage)), __int32_t(fps)))
            videoWriter.finishWriting(completionHandler: {
                self.moveVideoToPhotoLibrary(outputURL)
                self.showAlert(
                    title: "", message: "Exported a video with detected bones to photo library.", btnText: "OK",
                    completion: {
                        () -> Void in
                        self.updateSelectButton()
                    }
                )
            })
            
            DispatchQueue.main.async {
                self.messageLabel.isHidden = false
                
                if self.canUsePhotoLibrary! {
                    if self.canUseCamera! {
                        self.captureButton.isHidden = false
                    }
                    self.selectButton.isHidden = false
                }
                
                self.progressLabel.isHidden = true
                self.progressView.isHidden = true
            }
        }
    }
    
    func showAlert(title: String, message: String, btnText: String, completion: @escaping () -> Void = {}) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: btnText, style: .default, handler: nil))
        present(alert, animated: true, completion: completion)
    }
    
    func moveVideoToPhotoLibrary(_ url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url as URL)
        }){ completed, error in
            if error != nil {
                print("ERROR: Failed to move a video file to Photo Library.")
            }
        }
    }
    
    let ciContext = CIContext()
    var resultBuffer: CVPixelBuffer?
    
    func uiImageToPixelBuffer(_ uiImage: UIImage, targetSize: CGSize, orientation: UIImageOrientation) -> CVPixelBuffer? {
        var angle: CGFloat
            
        if orientation == UIImageOrientation.down {
            angle = CGFloat.pi
        } else if orientation == UIImageOrientation.up {
            angle = 0
        } else if orientation == UIImageOrientation.left {
            angle = CGFloat.pi / 2.0
        } else {
            angle = -CGFloat.pi / 2.0
        }
        
        let rotateTransform: CGAffineTransform = CGAffineTransform(translationX: targetSize.width / 2.0, y: targetSize.height / 2.0).rotated(by: angle).translatedBy(x: -targetSize.height / 2.0, y: -targetSize.width / 2.0)
        
        let uiImageResized = com.resizeImage(image: uiImage, size: targetSize, keepAspectRatio: true)
        let ciImage = CIImage(image: uiImageResized)!
        let rotated = ciImage.transformed(by: rotateTransform)
        
        // Only need to create this buffer one time and then we can reuse it for every frame
        if resultBuffer == nil {
            let result = CVPixelBufferCreate(kCFAllocatorDefault, Int(targetSize.width), Int(targetSize.height), kCVPixelFormatType_32BGRA, nil, &resultBuffer)
            
            guard result == kCVReturnSuccess else {
                fatalError("Can't allocate pixel buffer.")
            }
        }
        
        // Render the Core Image pipeline to the buffer
        ciContext.render(rotated, to: resultBuffer!)
        
        //  For debugging
        //  let image = imageBufferToUIImage(resultBuffer!)
        //  print(image.size) // set breakpoint to see image being provided to CoreML
        
        return resultBuffer
    }
    
    // Only used for debugging.
    // Turns an image buffer into a UIImage that is easier to display in the UI or debugger.
    func imageBufferToUIImage(_ imageBuffer: CVImageBuffer) -> UIImage {
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        let quartzImage = context!.makeImage()
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let image = UIImage(cgImage: quartzImage!, scale: 1.0, orientation: .right)
        
        return image
    }
}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        detectBone(outputFileURL)
        moveVideoToPhotoLibrary(outputFileURL)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func selectVideo() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imagePickerController.mediaTypes = ["public.movie"]
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        selectedFileURL = info["UIImagePickerControllerReferenceURL"] as? URL
        picker.dismiss(animated: true, completion: nil)
    }
}

class UILabelStroked: UILabel {
    var strokedText: String = "" {
        willSet(text) {
            let strokeTextAttributes = [
                NSAttributedStringKey.strokeColor : UIColor.white,
                NSAttributedStringKey.foregroundColor : UIColor.black,
                NSAttributedStringKey.strokeWidth : -2.0
            ] as [NSAttributedStringKey : Any]
            
            attributedText = NSMutableAttributedString(string: text, attributes: strokeTextAttributes)
        }
    }
}
