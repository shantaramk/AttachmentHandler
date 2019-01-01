//
//  AttachmentHandler.swift
//  HomeServices
//
//  Created by Shantaram Kokate on 12/17/18.
//  Copyright © 2018 Shantaram Kokate. All rights reserved.
//

import UIKit
import AVKit
import AssetsLibrary
import Photos
import MobileCoreServices

enum AttachmentType: String {
    case camera, video, photoLibrary
}

class AttachmentHandler: NSObject {
    
    // MARK: - Internal Properties
    
    static let shared = AttachmentHandler()
    fileprivate var currentVC: UIViewController?
    
    var imagePickedBlock: ((UIImage) -> Void)?
    var videoPickedBlock: ((NSURL) -> Void)?
    var filePickedBlock: ((URL) -> Void)?
    
    func showAttachmentActionSheet(viewController: UIViewController) {
        currentVC = viewController
        
        let actionSheetController: UIAlertController = UIAlertController(title: LocalizedStrings.cameraOption, message: LocalizedStrings.cameraSelectImage, preferredStyle: UIAlertControllerStyle.actionSheet)
        let cancelAction: UIAlertAction = UIAlertAction(title: LocalizedStrings.cameraCancel, style: .cancel) { _ -> Void in
        }
        
        actionSheetController.addAction(cancelAction)
        let takePictureAction: UIAlertAction = UIAlertAction(title: LocalizedStrings.cameraTakePicture, style: .default) { _ -> Void in
            self.authorisationStatus(attachmentTypeEnum: .camera, viewController: self.currentVC!)
        }
        actionSheetController.addAction(takePictureAction)
        
        let choosePictureAction: UIAlertAction = UIAlertAction(title: LocalizedStrings.selectFromCamraRool, style: .default) { _ -> Void in
            self.authorisationStatus(attachmentTypeEnum: .photoLibrary, viewController: self.currentVC!)
        }
        actionSheetController.addAction(choosePictureAction)
        
        // Hide the video and file picker option
        /*
        let chooseVideoAction: UIAlertAction = UIAlertAction(title: LocalizedStrings.selectFromCamraRool, style: .default) { _ -> Void in
            self.authorisationStatus(attachmentTypeEnum: .video, viewController: self.currentVC!)
        }
        actionSheetController.addAction(chooseVideoAction)
        
        let chooseFileAction: UIAlertAction = UIAlertAction(title: LocalizedStrings.selectFromCamraRool, style: .default) { _ -> Void in
            self.documentPicker()
        }
        actionSheetController.addAction(chooseFileAction) */
        viewController.present(actionSheetController, animated: true, completion: nil)
    }
    
    func authorisationStatus(attachmentTypeEnum: AttachmentType, viewController: UIViewController) {
        currentVC = viewController
        switch attachmentTypeEnum {
        case .camera:
            self.showCameraPermissionPopup(attachmentTypeEnum: attachmentTypeEnum)
        case .photoLibrary, .video:
            self.showphotoLibraryPermissionPopup(attachmentTypeEnum: attachmentTypeEnum)
        }
        
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = .camera
            currentVC?.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    private func showCameraPermissionPopup(attachmentTypeEnum: AttachmentType) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized: // The user has previously granted access to the camera.
            self.openCamera()
            
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.openCamera()
                }
            }
            //denied - The user has previously denied access.
        //restricted - The user can't grant access due to restrictions.
        case .denied, .restricted:
            self.addAlertForSettings(attachmentTypeEnum: .camera)
            return
        }
    }
    
    func photoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = .photoLibrary
            currentVC?.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    private func showphotoLibraryPermissionPopup(attachmentTypeEnum: AttachmentType) {
       
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            if attachmentTypeEnum == .photoLibrary {
                photoLibrary()
            }
            if attachmentTypeEnum == .video {
                videoLibrary()
            }
        case .denied, .restricted:
            self.addAlertForSettings(attachmentTypeEnum: .photoLibrary)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == PHAuthorizationStatus.authorized {
                    self.photoLibrary()
                }
                if attachmentTypeEnum == AttachmentType.video {
                    self.videoLibrary()
                }
            })
        }
    }
    
    func videoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = .photoLibrary
            myPickerController.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String]
            currentVC?.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    func documentPicker() {
        let importMenu = UIDocumentMenuViewController(documentTypes: [String(kUTTypePDF)], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        currentVC?.present(importMenu, animated: true, completion: nil)
    }
}

// MARK: - Private Methods

extension AttachmentHandler {
    
    func addAlertForSettings(attachmentTypeEnum: AttachmentType) {
        let alertView = AlertView(title: LocalizedStrings.cameraService, message: LocalizedStrings.cameraAccessMessage, okButtonText: LocalizedStrings.gotoSettting, cancelButtonText: AlertMessage.Cancel) { (_, button) in
            if button == .other {
                UIApplication.shared.open(URL.init(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
            }
        }
        alertView.show(animated: true)
    }
    
}

// MARK: - UIImagePicker Delegate

extension AttachmentHandler: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        
        // To handle image
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.imagePickedBlock?(image)
        } else {
            print("Something went wrong in  image")
        }
        // To handle video
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? NSURL {
            print("videourl: ", videoUrl)
            //trying compression of video
            let data = NSData(contentsOf: videoUrl as URL)!
            print("File size before compression: \(Double(data.length / 1048576)) mb")
            self.videoPickedBlock?(videoUrl)
        } else {
            print("Something went wrong in  video")
        }
        currentVC?.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        currentVC?.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - UIDocumentPicker Delegate

extension AttachmentHandler: UIDocumentPickerDelegate, UIDocumentMenuDelegate {
    
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        currentVC?.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("url", url)
        self.filePickedBlock?(url)
    }
    
    //    Method to handle cancel action.
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        currentVC?.dismiss(animated: true, completion: nil)
    }
    
}
