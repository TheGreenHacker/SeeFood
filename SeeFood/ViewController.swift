//
//  ViewController.swift
//  SeeFood
//
//  Created by Jack Li on 9/4/19.
//  Copyright © 2019 Jack Li. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let picker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.navigationItem.title = "Hi"
        // Do any additional setup after loading the view.
        picker.delegate = self
        picker.sourceType = .camera
    }
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        picker.cameraCaptureMode = .photo
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let uiImage = info[.originalImage] as? UIImage else { // show captured photo
            fatalError("No image found")
        }
        guard let ciImage = CIImage(image: uiImage) else { // for Vision and coreML frameworks
            fatalError("can't create CIImage from UIImage")
        }
        
        
        imageView.contentMode = .scaleAspectFill
        imageView.image = uiImage
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInteractive).async { // run classifier
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print(error)
            }
        }
    }
    
    lazy var classificationRequest: VNCoreMLRequest = {
        // Load the ML model through its generated class and create a Vision request for it.
        do {
            let model = try VNCoreMLModel(for: Inceptionv3().model)
            return VNCoreMLRequest(model: model, completionHandler: handleClassification)
        } catch {
            fatalError("Can't load Vision ML model: \(error).")
        }
    }()
    
    func handleClassification(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation]
            else { fatalError("Unexpected result type from VNCoreMLRequest.") }
        guard let best = results.first
            else { fatalError("Can't get best result.") }
        
        DispatchQueue.main.async { // get results and update UI accordingly
            let range = NSRange(location: 0, length: best.identifier.count)
            let regex = try! NSRegularExpression(pattern: "hot *dog")
            self.navigationItem.title = regex.firstMatch(in: best.identifier, options: [], range: range) != nil ? "Hot Dog!" : "Not Hot Dog!"
            self.navigationController?.navigationBar.barTintColor = self.navigationItem.title == "Hot Dog!" ? .green : .red

        }
    }
}

