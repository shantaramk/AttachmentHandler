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

enum AttachmentMenu {
    case camera, video, photoLibrary, document
}

class AttachmentHandler: NSObject {
    
    // MARK: - Internal Properties
    
    static let shared = AttachmentHandler()
    fileprivate var currentVC: UIViewController?
    var actionSheetController: UIAlertController?
    
    var imagePickedBlock: ((UIImage) -> Void)?
    var videoPickedBlock: ((NSURL) -> Void)?
    var filePickedBlock: ((URL) -> Void)?
    
    func showAttachmentActionSheet(_ attachmentMenu: [AttachmentMenu], taget: UIViewController) {
        currentVC = taget
        self.actionSheetController = nil
        for menu in attachmentMenu {
            actionSheet(with: menu)
        }
        currentVC!.present(actionSheetController!, animated: true, completion: nil)
        
    }
    
    func actionSheet(with attachmentMenu: AttachmentMenu) {
        
        if self.actionSheetController == nil {
            self.actionSheetController = UIAlertController(title: LocalizedStringConstant.cameraOption, message: LocalizedStringConstant.cameraSelectImage, preferredStyle: .actionSheet)
            let cancelAction: UIAlertAction = UIAlertAction(title: LocalizedStringConstant.cameraCancel, style: .cancel) { _ -> Void in
            }
            self.actionSheetController!.addAction(cancelAction)
            
        }
        
        switch attachmentMenu {
        case .camera:
            
            let takePictureAction: UIAlertAction = UIAlertAction(title: LocalizedStringConstant.cameraTakePicture, style: .default) { _ -> Void in
                self.authorisationStatus(attachmentTypeEnum: .camera, viewController: self.currentVC!)
            }
            self.actionSheetController!.addAction(takePictureAction)
            
        case .photoLibrary:
            
            let choosePictureAction: UIAlertAction = UIAlertAction(title: LocalizedStringConstant.selectFromCamraRool, style: .default) { _ -> Void in
                self.authorisationStatus(attachmentTypeEnum: .photoLibrary, viewController: self.currentVC!)
            }
            self.actionSheetController!.addAction(choosePictureAction)
            
        case .video:
            
            let chooseVideoAction: UIAlertAction = UIAlertAction(title: LocalizedStringConstant.selectFromCamraRool, style: .default) { _ -> Void in
                self.authorisationStatus(attachmentTypeEnum: .video, viewController: self.currentVC!)
            }
            self.actionSheetController!.addAction(chooseVideoAction)
            
        case .document:
            
            let chooseFileAction: UIAlertAction = UIAlertAction(title: LocalizedStringConstant.selectFromCamraRool, style: .default) { _ -> Void in
                self.documentPicker()
            }
            self.actionSheetController!.addAction(chooseFileAction)
            
        }
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
        DispatchQueue.main.async { () -> Void in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let myPickerController = UIImagePickerController()
                myPickerController.delegate = self
                myPickerController.sourceType = .camera
                self.currentVC?.present(myPickerController, animated: true, completion: nil)
            }
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
            
        @unknown default:
            break
        }
    }
    
    func photoLibrary() {
        DispatchQueue.main.async { () -> Void in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let myPickerController = UIImagePickerController()
                myPickerController.delegate = self
                myPickerController.sourceType = .photoLibrary
                self.currentVC?.present(myPickerController, animated: true, completion: nil)
            }
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
            
        @unknown default:
            break
        }
    }
    
    func videoLibrary() {
        DispatchQueue.main.async { () -> Void in
            
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let myPickerController = UIImagePickerController()
                myPickerController.delegate = self
                myPickerController.sourceType = .photoLibrary
                myPickerController.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String]
                self.currentVC?.present(myPickerController, animated: true, completion: nil)
            }
        }
    }
    
    func documentPicker() {
        DispatchQueue.main.async { () -> Void in
            let importMenu = UIDocumentMenuViewController(documentTypes: [String(kUTTypePDF)], in: .import)
            importMenu.delegate = self
            importMenu.modalPresentationStyle = .formSheet
            self.currentVC?.present(importMenu, animated: true, completion: nil)
        }
    }
}

// MARK: - Private Methods

extension AttachmentHandler {
    
    func addAlertForSettings(attachmentTypeEnum: AttachmentType) {
        GLOBALHELPER.showAlert(LocalizedStringConstant.cameraAccessMessage, okButtonText: LocalizedStringConstant.gotoSettting, cancelButtonText: LocalizedStringConstant.cancel, position: .bottom) { (_, button) in
            if button == .other {
                UIApplication.shared.open(URL.init(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }
        }
    }
    
}

// MARK: - UIImagePicker Delegate

extension AttachmentHandler: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.imagePickedBlock?(image)
        } else {
        }
        // To handle video
        if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL {
            //trying compression of video
            let data = NSData(contentsOf: videoUrl as URL)!
            print("File size before compression: \(Double(data.length / 1048576)) mb")
            self.videoPickedBlock?(videoUrl)
        } else {
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
        self.filePickedBlock?(url)
    }
    
    //    Method to handle cancel action.
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        currentVC?.dismiss(animated: true, completion: nil)
    }
    
}
